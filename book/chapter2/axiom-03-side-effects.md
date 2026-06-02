# Axiom 3 — Side effects

**A side effect is any interaction with state outside a function's parameters and return value.**

- Reading or writing global state, mutating a parameter, performing I/O, or consulting the clock all count.
- Naming side effects is the prerequisite for naming the functions that contain them.

> Side effects are named here so further axioms can refer to them. The point is not to avoid them — every useful program eventually does I/O — but to recognise them when you see them.

[Axiom 1](axiom-01-data-vs-behaviour.md) says data is a value; [Axiom 2](axiom-02-immutability.md) eliminates one source of bugs by making data unchangeable. This axiom adds the other source: code that reaches outside its declared interface, where the compiler has no way to see it.

This file is short on purpose. The rest of it is the recognition test — what counts as a side effect, what it looks like in code, and why naming the category matters before anything else can be said about it.

---

## Definitions

It says one structural thing: **a function performs a side effect whenever its execution depends on, or modifies, state that is not part of its declared parameters or return value.**

A call has a side effect when at least one of these is true:

- **It reads state outside its parameters** — a static field, a singleton, the system clock, a random source, the file system, the network, a cache.
- **It writes state outside its return value** — reassigns a static or instance field, mutates a passed object or collection, writes to a file, sends a network message, throws an exception, starts a thread.
- **Two calls with the same arguments may produce different results**, or may leave the program in observably different states.

A `void`-returning method is suspicious by default: a function that returns nothing must be doing *something* observable, which is to say, performing a side effect. A value-returning method can also carry effects, and that is the harder case — the return value distracts from the writes happening on the side.

---

## Example

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
public Order PlaceOrder(string customerId, List<string> items)
{
    var customer = repository.Find(customerId);           // I/O read
    if (items.Count == 0)
        throw new ArgumentException("no items");          // control-flow effect
    var order = new Order(customer, items, DateTime.Now); // clock read
    items.Clear();                                        // parameter mutation
    repository.Save(order);                               // I/O write
    logger.Info("placed order " + order.Id);              // logging
    eventBus.Publish(new OrderPlaced(order.Id));          // external message
    Interlocked.Increment(ref totalOrders);               // shared-state write
    return order;
}
```

</td>
<td>

```java
public Order placeOrder(String customerId, List<String> items) {
    Customer customer = repository.find(customerId);    // I/O read
    if (items.isEmpty())
        throw new IllegalArgumentException("no items"); // control-flow effect
    Order order = new Order(customer, items, LocalDateTime.now()); // clock read
    items.clear();                                      // parameter mutation
    repository.save(order);                             // I/O write
    logger.info("placed order {}", order.getId());      // logging
    eventBus.publish(new OrderPlaced(order.getId()));   // external message
    totalOrders.incrementAndGet();                      // shared-state write
    return order;
}
```

</td>
</tr>
</table>

The signature promises `(string, List<string>) -> Order`. The body delivers eight distinct effects beyond that promise — none of them named in the type, all of them visible to the world (or to other code) outside the call. Whether each of those effects is *necessary* or *misplaced* is the subject of later axioms; this axiom asks only that you can see them.

---

## The categories

- **Mutating a static field** — direct assignment; `volatile` writes; `Interlocked.*`; `AtomicInteger.set` / `incrementAndGet` / `compareAndSet`.
- **Mutating an instance field after construction** — setters; direct writes to public fields; any `this.x = ...` outside a constructor.
- **Mutating a parameter** — `list.Add` / `list.add`, `Remove`, `Clear`, `Insert`, `Array.Sort`, `Collections.sort`; setters on a passed object; reassigning a `ref` / `out` parameter.
- **Mutating a non-local collection** — writes to `ConcurrentDictionary`, `ConcurrentBag`, `BlockingCollection`, `HashMap`, `ConcurrentHashMap`, `Set`, `Queue` reachable from a static, instance, or captured variable.
- **File I/O** — `File.ReadAllText`, `File.WriteAllText`, `FileStream`, `Directory.*`, `File.Delete`, `File.SetAttributes`; `Files.readString`, `Files.write`, `FileInputStream`, `Files.list`, `Files.delete`, `Files.setPosixFilePermissions`.
- **Console I/O** — `Console.WriteLine`, `Console.ReadLine`, `Console.Out`, `Console.Error`; `System.out.println`, `System.err.println`, `Scanner.next`, `BufferedReader.readLine`.
- **Network I/O** — `HttpClient.GetAsync` / `SendAsync`, `Socket.Send` / `Receive`, gRPC, SignalR, WebSocket; `HttpClient.send`, `Socket.send` / `receive`, `URLConnection`; DNS lookups (`Dns.GetHostAddresses`, `InetAddress.getByName`).
- **Database I/O** — `SqlCommand.ExecuteReader`, `DbContext.SaveChanges`, EF / Dapper queries, `BeginTransaction` / `Commit` / `Rollback`; `PreparedStatement.executeQuery`, `EntityManager.persist`, Hibernate `flush`, JDBC `Connection.commit`.
- **Message-broker I/O** — `channel.basicPublish` (RabbitMQ), `kafkaProducer.send`, `kafkaConsumer.poll`, consumer acknowledgements; `IMessageSession.Send` (NServiceBus / MassTransit), `IServiceBus.Publish`.
- **Process and lifecycle** — `Process.Start`, `Environment.Exit`, `AppDomain.Unload`; `Runtime.exec`, `System.exit`, `Runtime.getRuntime().addShutdownHook`; loading native libraries (`Assembly.LoadFrom`, `System.loadLibrary`).
- **Environment reads** — `Environment.GetEnvironmentVariable`, `Environment.CommandLine`, `Environment.MachineName`, `Environment.UserName`; `System.getenv`, `System.getProperty`, `args[]`, `InetAddress.getLocalHost`.
- **Reading the clock** — `DateTime.Now`, `DateTime.UtcNow`, `DateTimeOffset.Now`, `Stopwatch.GetTimestamp`, `Environment.TickCount`; `LocalDateTime.now()`, `Instant.now()`, `System.currentTimeMillis()`, `System.nanoTime()`, `Clock.systemDefaultZone()`.
- **Randomness** — `Random`, `Random.Shared`, `RandomNumberGenerator.GetBytes`, `Guid.NewGuid()`; `new Random()`, `SecureRandom.nextBytes`, `ThreadLocalRandom.current()`, `UUID.randomUUID()`, `Math.random()`.
- **Logging** — every `logger.Info` / `Debug` / `Warn` / `Error`, `Trace.WriteLine`, `Debug.WriteLine`, `EventSource.Write`; `slf4j.Logger.*`, `java.util.logging.Logger.*`, `Log4j Logger.*`; structured-logger emits and log-context (`MDC`, `LogContext`) writes.
- **Throwing exceptions** — `throw new ...`, `throw;` rethrows; Java checked (declared in `throws`) and unchecked alike.
- **Threading** — `new Thread().Start()`, `Task.Run`, `Task.Factory.StartNew`, `Parallel.For` / `ForEach`, `ThreadPool.QueueUserWorkItem`; `new Thread().start()`, `ExecutorService.submit`, `CompletableFuture.runAsync`, `ForkJoinPool.commonPool().submit`, virtual-thread `start()`.
- **Sleeping / blocking** — `Thread.Sleep`, `Task.Delay`, `SpinWait`, `Monitor.Wait`; `Thread.sleep`, `LockSupport.parkNanos`, `Object.wait`, `BlockingQueue.take`.
- **Synchronisation primitives** — `lock`, `Monitor.Enter` / `Exit`, `Mutex`, `Semaphore`, `SemaphoreSlim`, `ReaderWriterLockSlim`; `synchronized`, `ReentrantLock`, `ReentrantReadWriteLock`, `CountDownLatch.await`, `Semaphore.acquire`, `CyclicBarrier.await`.
- **Atomic / volatile / memory-barrier operations** — `Interlocked.*`, `Volatile.Read` / `Write`, `Thread.MemoryBarrier`; `AtomicReference`, `VarHandle.compareAndSet`, `volatile` reads.
- **Externally-triggered callbacks** — `[HttpGet]`, `[HttpPost]`, ASP.NET handlers; `@GetMapping`, `@PostMapping`, Spring controllers; `@RabbitListener`, `@KafkaListener`, `@JmsListener`, `@EventListener`, `@SqsListener`; `@Scheduled`, `Timer` ticks, `ScheduledExecutorService` callbacks; signal handlers, `event += handler` subscriptions, WebSocket / SignalR callbacks.
- **Cache reads and writes** — `IMemoryCache.Set` / `TryGetValue`, `IDistributedCache`, `LazyCache`; `Caffeine.put` / `getIfPresent`, `Guava Cache`, Redisson, Jedis, Ehcache.
- **Singletons and service locators** — `Singleton.Instance`, `getInstance()`, `IServiceProvider.GetService` / `GetRequiredService`, `ServiceLocator.Current`; `ApplicationContext.getBean`, `CDI.current().select(...)`.
- **Connection / object pools** — `HikariCP.getConnection`, pooled `SqlConnection.Open`, `ArrayPool<T>.Shared.Rent` / `Return`, `MemoryPool<T>`; `DataSource.getConnection`, pooled `ByteBuffer.allocateDirect`.
- **Ambient context** — `ThreadLocal<T>.Value`, `AsyncLocal<T>.Value`, `HttpContext.Current`, `OperationContext.Current`, `CallContext.LogicalGetData`; `RequestContextHolder.getRequestAttributes()`, `MDC.get` / `put`, `TransactionSynchronizationManager`.
- **Runtime configuration reads** — `IConfiguration["..."]`, `IOptions<T>.Value`, `ConfigurationManager.AppSettings`; `@Value("${...}")`, Spring `Environment.getProperty`; feature flags (`IFeatureManager`, LaunchDarkly, GrowthBook, ConfigCat, Unleash); secrets stores (Vault, Consul, etcd, Azure Key Vault, AWS SSM).
- **Reflection that reads or mutates** — `FieldInfo.GetValue` / `SetValue`, `PropertyInfo.SetValue`, `MethodInfo.Invoke`, `Activator.CreateInstance`; `Field.get` / `set`, `Method.invoke`, `Constructor.newInstance`.
- **Dynamic dispatch through interfaces with side-effecting implementations** — any call through an interface whose impl performs any of the above; the static type hides the effect.
- **Native interop** — `[DllImport]` / P/Invoke, COM calls, `Marshal.*`; JNI, JNA, Project Panama FFI, foreign linker calls.
- **Locale- and culture-dependent calls** — `string.ToUpper()` / `ToLower()` without `CultureInfo`; `String.toUpperCase()` / `toLowerCase()` without `Locale`; `DateTime.Parse`, `decimal.Parse`, `SimpleDateFormat` defaults; reads of `CultureInfo.CurrentCulture`, `Thread.CurrentCulture`, `Locale.getDefault()`.
- **Process / thread identity reads** — `Process.GetCurrentProcess().Id`, `Environment.ProcessId`, `Thread.CurrentThread.ManagedThreadId`; `ProcessHandle.current().pid()`, `Thread.currentThread().getId()`.
- **GC and runtime control** — `GC.Collect`, `GC.AddMemoryPressure`, `GC.SuppressFinalize`, `GCSettings.*`; `System.gc()`, `Runtime.getRuntime().freeMemory()`, `Cleaner.register`, finalizer scheduling.
- **Disposal and resource release** — `Dispose()`, `IAsyncDisposable.DisposeAsync`, `using` / `await using` exit; `close()`, `AutoCloseable.close()`, try-with-resources exit.
- **Async continuation scheduling** — `await`'s `SynchronizationContext` / `TaskScheduler` capture and post-back; `CompletableFuture.thenApply` dispatching onto a captured executor.
- **Default hashing and identity** — `object.GetHashCode()` for reference types; .NET Core's per-process randomised `string.GetHashCode()`; `Object.hashCode()` identity-based default; `WeakReference<T>.TryGetTarget`.

---

## Problem / forces

Three things become impossible if side effects are not named as a category:

1. **Local reasoning.** A function whose result depends on hidden inputs (the clock, a cache, a singleton) is one whose meaning is non-local: to understand the call site, you have to understand the world around it. Naming the category is the first step toward separating the calls that need that world from the ones that do not.
2. **Testability.** A function with hidden writes mutates state the test cannot see; a function with hidden reads depends on state the test cannot pin. Either way, the test rig grows heavier than the function under test.
3. **Concurrency.** A function that shares mutable state with other functions cannot run safely beside them without coordination; one that does not, can. The distinction is invisible until effects are named.

The competing force is **convenience**: every line-of-business function eventually does something — reads the database, writes a log, sends an event — and forcing yourself to track which is which is overhead. The axiom does not deny this force; it relocates it. Tracking is cheap once the category has a name; without the name, it is not even possible.

---

## Why

**1. The compiler will not flag effects for you.**
A `void` return is the loudest signal, but not the only one — and not every `void` function is pure ceremony. A value-returning method can also carry effects, and neither Java's nor C#'s type system will warn the reader. Recognising effects is therefore a *reading* discipline, and the only way to make it operational is to name the category before applying it.

**2. Effects are how programs touch the world.**
Without side effects, a program is a mathematical function: given inputs, it produces outputs and changes nothing observable. Such a program has no use — it cannot save a file, send a message, draw a pixel, or learn the time of day. Every useful program has effects somewhere. The question, which later axioms will answer, is *where*: scattered through every function, or concentrated at the edges.

**3. Effects are the source of most non-local bugs.**
A function whose result depends on hidden inputs is hard to test and hard to reproduce — changing something far away changes its behaviour. A function whose body performs hidden writes is the same problem in reverse: changing what it does ripples out into code that does not call it directly. Naming the category is the prerequisite for asking *which* effects a given function has and *which* of those can be moved elsewhere.

---

## Trade-offs

There is no cost to *naming* side effects; recognition is a reading skill, not a coding constraint. The real trade-offs appear in later axioms — the ones that prescribe where in a program the effects should and should not live. Those choices have real costs (testability vs ergonomics, allocation, friction with frameworks); this axiom asks only that you can spot an effect when you see one.

---

## When NOT to

Two edge cases where the recognition test produces an awkward answer, and what to do with them:

- **Memoisation caches that look pure from outside.** A function that caches its result by argument behaves indistinguishably from a pure function on identical arguments — but the cache itself is mutable shared state. The honest read is "the cache is the effect; the memoised function is a value-returning façade around it." The heuristic above (replace with a constant in a test) flags the cache, not the façade.
- **Read-only globals loaded once at startup.** Configuration loaded once and never reassigned is technically a static read, but it behaves as a constant for the lifetime of the process. In practice, inject it as a parameter and the question goes away. If you keep it as a static read, label it an effect and decide separately whether you care.

Deterministic logging is *not* an edge case — it is still a write to a logger, and the recognition test does not care about determinism. A function whose only effect is logging is still a function with an effect.

---

## References

[1] **Rich Hickey**, *Simple Made Easy*, Strange Loop 2011. The argument that *complecting* effects with values is the root cause of incidental complexity in OO code. A `void`-returning function communicates nothing through its result — therefore, by elimination, it must be doing something observable elsewhere, and the type system has not warned the reader. Recording on InfoQ: <https://www.infoq.com/presentations/Simple-Made-Easy/>.

[2] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Chapters 2 and 3 give the same recognition test this axiom uses, framed as "actions" vs "calculations": a calculation is a pure computation; an action is anything whose outcome depends on when, or how often, it is called.
<https://www.manning.com/books/grokking-simplicity>

[3] **John Hughes**, *Why Functional Programming Matters*, Research Topics in Functional Programming, Addison-Wesley, 1990. The original case for treating functions as composable values. Hughes' argument turns on functions being free of hidden inputs and hidden outputs — i.e., free of side effects — which is what makes composition tractable to begin with.
