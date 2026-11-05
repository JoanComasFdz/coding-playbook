# Axiom 3 — Side effects

**A side effect is any interaction with state outside a function's parameters and return value.**

- Reading or writing global state, changing a parameter, doing I/O and reading the clock all count.
- Naming side effects comes first: only then can we name the functions that contain them.

This axiom names side effects so later axioms can refer to them. The point is not to avoid them; every useful program does I/O eventually. The point is to recognize them when you see them.

[Axiom 1](axiom-01-data-is-not-behavior.md) says data is a value, and [Axiom 2](axiom-02-immutability.md) removes one source of bugs by making data unchangeable. This axiom adds another source: code that reaches outside its declared interface, where the compiler can't see it.

Most of this file is the recognition test: what counts as a side effect, what it looks like in code, and why the category needs a name before anything else can be said about it.

---

## Definitions

In one sentence: **a function has a side effect when it depends on, or changes, state that is not part of its parameters or its return value.**

A call has a side effect when at least one of these is true:

- **It reads state outside its parameters:** a static field, a singleton, the system clock, a random source, the file system, the network, a cache.
- **It writes state outside its return value:** it reassigns a static or instance field, changes a passed object or collection, writes to a file, sends a network message, throws an exception or starts a thread.
- **Two calls with the same arguments can give different results**, or leave the program in observably different states.

Normand calls the same split *actions* versus *calculations*: a calculation only computes; an action is anything whose outcome depends on when, or how often, it runs [2].

A `void` method is suspicious by default. A function that returns nothing is almost always doing *something* observable, and that something is a side effect. A method that returns a value can have effects too, and that is the harder case: the return value distracts you from the writes happening on the side.

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

The signature promises `(string, List<string>) -> Order`. The body delivers eight effects beyond that promise. None of them is named in the type, and all of them are visible to the world, or to other code, outside the call. Whether each effect is *necessary* or *misplaced* is a question for later axioms. This one only asks that you can see them.

---

## The categories

A reference list. You don't need to memorize it; skim it once, and come back when you're unsure whether a call is an effect.

- **Mutating a static field**: direct assignment; `volatile` writes; `Interlocked.*`; `AtomicInteger.set` / `incrementAndGet` / `compareAndSet`.
- **Mutating an instance field after construction**: setters; direct writes to public fields; any `this.x = ...` outside a constructor.
- **Mutating a parameter**: `list.Add` / `list.add`, `Remove`, `Clear`, `Insert`, `Array.Sort`, `Collections.sort`; setters on a passed object; reassigning a `ref` / `out` parameter.
- **Mutating a non-local collection**: writes to `ConcurrentDictionary`, `ConcurrentBag`, `BlockingCollection`, `HashMap`, `ConcurrentHashMap`, `Set`, `Queue` reachable from a static, instance, or captured variable.
- **File I/O**: `File.ReadAllText`, `File.WriteAllText`, `FileStream`, `Directory.*`, `File.Delete`, `File.SetAttributes`; `Files.readString`, `Files.write`, `FileInputStream`, `Files.list`, `Files.delete`, `Files.setPosixFilePermissions`.
- **Console I/O**: `Console.WriteLine`, `Console.ReadLine`, `Console.Out`, `Console.Error`; `System.out.println`, `System.err.println`, `Scanner.next`, `BufferedReader.readLine`.
- **Network I/O**: `HttpClient.GetAsync` / `SendAsync`, `Socket.Send` / `Receive`, gRPC, SignalR, WebSocket; `HttpClient.send`, `Socket.send` / `receive`, `URLConnection`; DNS lookups (`Dns.GetHostAddresses`, `InetAddress.getByName`).
- **Database I/O**: `SqlCommand.ExecuteReader`, `DbContext.SaveChanges`, EF / Dapper queries, `BeginTransaction` / `Commit` / `Rollback`; `PreparedStatement.executeQuery`, `EntityManager.persist`, Hibernate `flush`, JDBC `Connection.commit`.
- **Message-broker I/O**: `channel.basicPublish` (RabbitMQ), `kafkaProducer.send`, `kafkaConsumer.poll`, consumer acknowledgements; `IMessageSession.Send` (NServiceBus), `IPublishEndpoint.Publish` (MassTransit).
- **Process and lifecycle**: `Process.Start`, `Environment.Exit`, `AppDomain.Unload`; `Runtime.exec`, `System.exit`, `Runtime.getRuntime().addShutdownHook`; loading code at runtime (`Assembly.LoadFrom`, `NativeLibrary.Load`; `System.loadLibrary`).
- **Environment reads**: `Environment.GetEnvironmentVariable`, `Environment.CommandLine`, `Environment.MachineName`, `Environment.UserName`; `System.getenv`, `System.getProperty`, `InetAddress.getLocalHost`.
- **Reading the clock**: `DateTime.Now`, `DateTime.UtcNow`, `DateTimeOffset.Now`, `Stopwatch.GetTimestamp`, `Environment.TickCount`; `LocalDateTime.now()`, `Instant.now()`, `System.currentTimeMillis()`, `System.nanoTime()`, `Clock.systemDefaultZone()`.
- **Randomness**: `Random`, `Random.Shared`, `RandomNumberGenerator.GetBytes`, `Guid.NewGuid()`; `new Random()`, `SecureRandom.nextBytes`, `ThreadLocalRandom.current()`, `UUID.randomUUID()`, `Math.random()`.
- **Logging**: every `logger.Info` / `Debug` / `Warn` / `Error`, `Trace.WriteLine`, `Debug.WriteLine`, `EventSource.Write`; `slf4j.Logger.*`, `java.util.logging.Logger.*`, `Log4j Logger.*`; structured-logger emits and log-context (`MDC`, `LogContext`) writes.
- **Throwing exceptions**: `throw new ...`, `throw;` rethrows; Java checked (declared in `throws`) and unchecked alike.
- **Threading**: `new Thread().Start()`, `Task.Run`, `Task.Factory.StartNew`, `Parallel.For` / `ForEach`, `ThreadPool.QueueUserWorkItem`; `new Thread().start()`, `ExecutorService.submit`, `CompletableFuture.runAsync`, `ForkJoinPool.commonPool().submit`, virtual-thread `start()`.
- **Sleeping / blocking**: `Thread.Sleep`, `Task.Delay`, `SpinWait`, `Monitor.Wait`; `Thread.sleep`, `LockSupport.parkNanos`, `Object.wait`, `BlockingQueue.take`.
- **Synchronization primitives**: `lock`, `Monitor.Enter` / `Exit`, `Mutex`, `Semaphore`, `SemaphoreSlim`, `ReaderWriterLockSlim`; `synchronized`, `ReentrantLock`, `ReentrantReadWriteLock`, `CountDownLatch.await`, `Semaphore.acquire`, `CyclicBarrier.await`.
- **Atomic / volatile / memory-barrier operations**: `Interlocked.*`, `Volatile.Read` / `Write`, `Thread.MemoryBarrier`; `AtomicReference`, `VarHandle.compareAndSet`, `volatile` reads.
- **Externally-triggered callbacks**: `[HttpGet]`, `[HttpPost]`, ASP.NET handlers; `@GetMapping`, `@PostMapping`, Spring controllers; `@RabbitListener`, `@KafkaListener`, `@JmsListener`, `@EventListener`, `@SqsListener`; `@Scheduled`, `Timer` ticks, `ScheduledExecutorService` callbacks; signal handlers, `event += handler` subscriptions, WebSocket / SignalR callbacks.
- **Cache reads and writes**: `IMemoryCache.Set` / `TryGetValue`, `IDistributedCache`, `LazyCache`; Caffeine `Cache.put` / `getIfPresent`, Guava `Cache`, Redisson, Jedis, Ehcache.
- **Singletons and service locators**: `Singleton.Instance`, `getInstance()`, `IServiceProvider.GetService` / `GetRequiredService`, `ServiceLocator.Current`; `ApplicationContext.getBean`, `CDI.current().select(...)`.
- **Connection / object pools**: `HikariDataSource.getConnection` (HikariCP), pooled `SqlConnection.Open`, `ArrayPool<T>.Shared.Rent` / `Return`, `MemoryPool<T>`; `DataSource.getConnection`.
- **Ambient context**: `ThreadLocal<T>.Value`, `AsyncLocal<T>.Value`, `HttpContext.Current`, `OperationContext.Current`, `CallContext.LogicalGetData`; `RequestContextHolder.getRequestAttributes()`, `MDC.get` / `put`, `TransactionSynchronizationManager`.
- **Runtime configuration reads**: `IConfiguration["..."]`, `IOptions<T>.Value`, `ConfigurationManager.AppSettings`; `@Value("${...}")`, Spring `Environment.getProperty`; feature flags (`IFeatureManager`, LaunchDarkly, GrowthBook, ConfigCat, Unleash); secrets stores (Vault, Consul, etcd, Azure Key Vault, AWS SSM).
- **Reflection that reads or mutates**: `FieldInfo.GetValue` / `SetValue`, `PropertyInfo.SetValue`, `MethodInfo.Invoke`, `Activator.CreateInstance`; `Field.get` / `set`, `Method.invoke`, `Constructor.newInstance`.
- **Dynamic dispatch through interfaces with side-effecting implementations**: any call through an interface whose impl performs any of the above; the static type hides the effect.
- **Native interop**: `[DllImport]` / P/Invoke, COM calls, `Marshal.*`; JNI, JNA, Project Panama FFI, foreign linker calls.
- **Locale- and culture-dependent calls**: `string.ToUpper()` / `ToLower()` without `CultureInfo`; `String.toUpperCase()` / `toLowerCase()` without `Locale`; `DateTime.Parse`, `decimal.Parse`, `SimpleDateFormat` defaults; reads of `CultureInfo.CurrentCulture`, `Thread.CurrentCulture`, `Locale.getDefault()`.
- **Process / thread identity reads**: `Process.GetCurrentProcess().Id`, `Environment.ProcessId`, `Thread.CurrentThread.ManagedThreadId`; `ProcessHandle.current().pid()`, `Thread.currentThread().getId()`.
- **GC and runtime control**: `GC.Collect`, `GC.AddMemoryPressure`, `GC.SuppressFinalize`, `GCSettings.*`; `System.gc()`, `Runtime.getRuntime().freeMemory()`, `Cleaner.register`, finalizer scheduling.
- **Disposal and resource release**: `Dispose()`, `IAsyncDisposable.DisposeAsync`, `using` / `await using` exit; `close()`, `AutoCloseable.close()`, try-with-resources exit.
- **Async continuation scheduling**: `await`'s `SynchronizationContext` / `TaskScheduler` capture and post-back; `CompletableFuture.thenApply` dispatching onto a captured executor.
- **Default hashing and identity**: `object.GetHashCode()` for reference types; .NET Core's per-process randomized `string.GetHashCode()`; `Object.hashCode()` identity-based default; `WeakReference<T>.TryGetTarget`.

---

## Problem / forces

If side effects are not named as a category, three things get much harder:

1. **Local reasoning.** A function whose result depends on hidden inputs (the clock, a cache, a singleton) can't be understood on its own: to understand the call, you have to understand the world around it. Naming the category is the first step toward separating the calls that need that world from the ones that don't. Composing functions relies on the same property: no hidden inputs or outputs [3].
2. **Testing.** A function with hidden writes changes state the test can't see. A function with hidden reads depends on state the test can't control. Either way, the test setup grows bigger than the function under test.
3. **Concurrency.** A function that shares mutable state with others can't run safely beside them without coordination; one that doesn't share, can. You can't tell which is which until effects are named.

One force pulls the other way: **convenience**. Every line-of-business function eventually does something (reads the database, writes a log, sends an event), and tracking which is which feels like overhead. This axiom doesn't ask you to stop. It only asks you to see them, and seeing is cheap once the category has a name.

---

## Why

**1. The compiler won't flag effects for you.**
A `void` return is the loudest signal, but not the only one. A method that returns a value can also have effects, and neither C#'s nor Java's type system warns the reader. So recognizing effects is a *reading* skill, and you can only practice it once the category has a name.

**2. Effects are how programs touch the world.**
Without side effects, a program is a mathematical function: it takes inputs, produces outputs, and changes nothing observable. Such a program is useless: it can't save a file, send a message, draw a pixel or learn the time of day. Every useful program has effects somewhere. The question, which later axioms answer, is *where*: scattered through every function, or gathered at the edges.

**3. Effects are a common source of non-local bugs.**
A function whose result depends on hidden inputs is hard to test and hard to reproduce: changing something far away changes its behavior. A function with hidden writes is the same problem in reverse: changing what it does ripples into code that never calls it. Mixing state into what should be plain values is, in Hickey's words, a root of incidental complexity [1]. Naming the category is what lets you ask *which* effects a function has, and *which* of them could move elsewhere.

---

## Trade-offs

*Naming* side effects costs nothing: recognizing them is a reading skill, not a coding constraint. The real trade-offs come in later axioms, the ones that say where in a program effects should and shouldn't live. Those choices have real costs (ergonomics, allocation, friction with frameworks). This axiom only asks that you can spot an effect.

---

## When NOT to

There is no case where you shouldn't recognize an effect. But two cases give an awkward answer:

- **Memoization caches that look pure from outside.** A function that [memoizes](https://en.wikipedia.org/wiki/Memoization) its result per argument behaves exactly like a function without the cache. But the cache itself is mutable shared state. The honest reading: the cache is the effect, and the memoized function is a value-returning front for it.
- **Read-only globals loaded once at startup.** Configuration that is loaded once and never reassigned is technically a static read, but it acts like a constant for the life of the process. In practice, pass it in as a parameter and the question goes away. If you keep it as a static read, call it an effect, and decide separately whether you care.

Logging is *not* an edge case, even when it is deterministic. It is still a write to a logger. A function whose only effect is logging is still a function with an effect.

---

## References

[1] **Rich Hickey**, *Simple Made Easy*, Strange Loop 2011. Argues that *complecting* (braiding together) things like state, time and values is a root cause of incidental complexity. Recording on InfoQ: <https://www.infoq.com/presentations/Simple-Made-Easy/>.

[2] **Eric Normand**, *Grokking Simplicity*, Manning Publications, 2021. Chapters 2 and 3 give the same recognition test this axiom uses, framed as *actions* versus *calculations*: a calculation is a pure computation; an action is anything whose outcome depends on when, or how often, it is called. <https://www.manning.com/books/grokking-simplicity>

[3] **John Hughes**, *Why Functional Programming Matters*, in *Research Topics in Functional Programming*, Addison-Wesley, 1990. The classic case for treating functions as composable values. Hughes' argument relies on functions having no hidden inputs or outputs, that is, no side effects; that is what makes composing them manageable.

---

← Previous: [Axiom 2 — Immutability](axiom-02-immutability.md) · Next: [Axiom 4 — Impure functions](axiom-04-impure-functions.md) →
