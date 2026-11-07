# Axiom 4 — Side effects

**A side effect is any interaction with state outside a function's parameters and return value.**

- Reading or writing global state, changing a parameter, doing I/O and reading the clock all count.
- Naming side effects comes first: only then can we name the functions that contain them.

This axiom names side effects so later axioms can refer to them. The point is not to avoid them; every useful program does I/O eventually. The point is to recognize them when you see them.

[Axiom 2](axiom-02-data-is-not-behavior.md) says data is a value, and [Axiom 3](axiom-03-immutability.md) removes one source of bugs by making data unchangeable. This axiom adds another source: code that reaches outside its declared interface, where the compiler can't see it.

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

The signature promises `(string, List<string>) -> Order`. The body delivers eight effects beyond that promise. None of them is named in the type, and all of them are visible to the world, or to other code, outside the call. One of them is also a bug: `Order` keeps a reference to `items`, so clearing the parameter empties the order's list too. A hidden write rarely stays local.

Whether each effect is *necessary* or *misplaced* is a question for later axioms. This one only asks that you can see them.

---

## The categories

A reference list. You don't need to memorize it; skim it once, and come back when you're unsure whether a call is an effect.

### State

| Category | C# | Java |
|---|---|---|
| Writing a static field | direct assignment, `volatile` writes, `Interlocked.*` | direct assignment, `volatile` writes, `AtomicInteger.set` / `incrementAndGet` / `compareAndSet` |
| Writing an instance field after construction | setters, writes to public fields, any `this.x = ...` outside a constructor | setters, writes to public fields, any `this.x = ...` outside a constructor |
| Changing a parameter | `list.Add`, `Remove`, `Clear`, `Insert`, `Array.Sort`, setters on a passed object, assigning a `ref` / `out` parameter | `list.add`, `remove`, `clear`, `Collections.sort`, `Arrays.sort`, setters on a passed object |
| Changing a non-local collection (reachable from a static, instance or captured variable) | `List`, `Dictionary`, `ConcurrentDictionary`, `ConcurrentBag`, `BlockingCollection` | `ArrayList`, `HashMap`, `ConcurrentHashMap`, `Set`, `Queue` |
| Cache reads and writes | `IMemoryCache.Set` / `TryGetValue`, `IDistributedCache`, LazyCache | Caffeine `Cache.put` / `getIfPresent`, Guava `Cache`, Ehcache, Redisson, Jedis |
| Singletons and service locators | `Singleton.Instance`, `IServiceProvider.GetService` / `GetRequiredService`, `ServiceLocator.Current` | `getInstance()`, `ApplicationContext.getBean`, `CDI.current().select(...)` |
| Ambient context | `AsyncLocal<T>.Value`, `ThreadLocal<T>.Value`, `IHttpContextAccessor.HttpContext`, `HttpContext.Current`, `OperationContext.Current`, `CallContext.LogicalGetData` | `ThreadLocal.get` / `set`, `RequestContextHolder.getRequestAttributes()`, `MDC.get` / `put`, `TransactionSynchronizationManager` |

### I/O

| Category | C# | Java |
|---|---|---|
| File | `File.ReadAllText`, `File.WriteAllText`, `FileStream`, `Directory.*`, `File.Delete`, `File.SetAttributes` | `Files.readString`, `Files.write`, `FileInputStream`, `Files.list`, `Files.delete`, `Files.setPosixFilePermissions` |
| Console | `Console.WriteLine`, `Console.ReadLine`, `Console.Out`, `Console.Error` | `System.out.println`, `System.err.println`, `Scanner.next`, `BufferedReader.readLine` |
| Network | `HttpClient.GetAsync` / `SendAsync`, `Socket.Send` / `Receive`, gRPC, SignalR, WebSocket, DNS lookups (`Dns.GetHostAddresses`) | `HttpClient.send`, `Socket` streams, `DatagramSocket.send` / `receive`, `URLConnection`, gRPC, WebSocket, DNS lookups (`InetAddress.getByName`) |
| Database | `SqlCommand.ExecuteReader`, `DbContext.SaveChanges`, EF / Dapper queries, `BeginTransaction` / `Commit` / `Rollback` | `PreparedStatement.executeQuery`, `EntityManager.persist`, Hibernate `flush`, `Connection.commit` |
| Message broker | RabbitMQ `channel.BasicPublish`, Kafka `producer.Produce` / `consumer.Consume`, `IMessageSession.Send` (NServiceBus), `IPublishEndpoint.Publish` (MassTransit), consumer acknowledgements | RabbitMQ `channel.basicPublish`, `KafkaProducer.send`, `KafkaConsumer.poll`, Spring `KafkaTemplate.send` / `RabbitTemplate.convertAndSend`, consumer acknowledgements |

### Time, randomness and environment

| Category | C# | Java |
|---|---|---|
| Reading the clock | `DateTime.Now`, `DateTime.UtcNow`, `DateTimeOffset.Now`, `Stopwatch.GetTimestamp`, `Environment.TickCount` | `LocalDateTime.now()`, `Instant.now()`, `System.currentTimeMillis()`, `System.nanoTime()`, `Clock.systemDefaultZone()` |
| Randomness | `Random`, `Random.Shared`, `RandomNumberGenerator.GetBytes`, `Guid.NewGuid()` | `new Random()`, `SecureRandom.nextBytes`, `ThreadLocalRandom.current()`, `UUID.randomUUID()`, `Math.random()` |
| Environment reads | `Environment.GetEnvironmentVariable`, `Environment.CommandLine`, `Environment.MachineName`, `Environment.UserName` | `System.getenv`, `System.getProperty`, `InetAddress.getLocalHost` |
| Runtime configuration | `IConfiguration["..."]`, `IOptions<T>.Value`, `ConfigurationManager.AppSettings`, `IFeatureManager` | `@Value("${...}")`, Spring `Environment.getProperty` |
| Feature-flag and secrets services | LaunchDarkly, GrowthBook, ConfigCat, Unleash; Vault, Consul, etcd, Azure Key Vault, AWS SSM | the same services, through their Java SDKs |
| Culture- and locale-dependent calls | `ToUpper()` / `ToLower()` without a `CultureInfo`, `DateTime.Parse`, `decimal.Parse`, `CultureInfo.CurrentCulture`, `Thread.CurrentThread.CurrentCulture` | `toUpperCase()` / `toLowerCase()` without a `Locale`, `SimpleDateFormat` defaults, `Locale.getDefault()` |
| Process and thread identity | `Process.GetCurrentProcess().Id`, `Environment.ProcessId`, `Thread.CurrentThread.ManagedThreadId` | `ProcessHandle.current().pid()`, `Thread.currentThread().threadId()` |
| Default hashing and identity | default `object.GetHashCode()` for reference types, per-process randomized `string.GetHashCode()`, `WeakReference<T>.TryGetTarget` | identity-based default `Object.hashCode()`, `System.identityHashCode`, `WeakReference.get` |

### Concurrency and runtime

| Category | C# | Java |
|---|---|---|
| Starting threads and tasks | `new Thread().Start()`, `Task.Run`, `Task.Factory.StartNew`, `Parallel.For` / `ForEach`, `ThreadPool.QueueUserWorkItem` | `new Thread().start()`, `ExecutorService.submit`, `CompletableFuture.runAsync`, `ForkJoinPool.commonPool().submit`, virtual-thread `start()` |
| Sleeping and blocking | `Thread.Sleep`, `Task.Delay`, `SpinWait`, `Monitor.Wait` | `Thread.sleep`, `LockSupport.parkNanos`, `Object.wait`, `BlockingQueue.take` |
| Synchronization primitives | `lock`, `Monitor.Enter` / `Exit`, `Mutex`, `Semaphore`, `SemaphoreSlim`, `ReaderWriterLockSlim` | `synchronized`, `ReentrantLock`, `ReentrantReadWriteLock`, `CountDownLatch.await`, `Semaphore.acquire`, `CyclicBarrier.await` |
| Atomics, volatile and memory barriers | `Interlocked.*`, `Volatile.Read` / `Write`, `Thread.MemoryBarrier` | `AtomicReference`, `VarHandle.compareAndSet`, `volatile` reads and writes |
| Async continuation scheduling | `await` capturing the `SynchronizationContext` / `TaskScheduler` and posting back to it | `CompletableFuture.thenApplyAsync` running on a captured executor |
| Connection and object pools | pooled `SqlConnection.Open`, `ArrayPool<T>.Shared.Rent` / `Return`, `MemoryPool<T>` | `DataSource.getConnection` (for example HikariCP's `HikariDataSource`) |
| Disposal and resource release | `Dispose()`, `DisposeAsync()`, leaving a `using` / `await using` block | `close()`, leaving a try-with-resources block |
| GC and runtime control | `GC.Collect`, `GC.AddMemoryPressure`, `GC.SuppressFinalize`, `GCSettings.*` | `System.gc()`, `Runtime.getRuntime().freeMemory()`, `Cleaner.register`, finalizers |
| Process and lifecycle | `Process.Start`, `Environment.Exit`, `AssemblyLoadContext.Unload`, loading code at runtime (`Assembly.LoadFrom`, `NativeLibrary.Load`) | `ProcessBuilder.start`, `Runtime.exec`, `System.exit`, `Runtime.addShutdownHook`, `System.loadLibrary` |

### Indirect

| Category | C# | Java |
|---|---|---|
| Throwing exceptions | `throw new ...`, `throw;` rethrows | `throw new ...`, checked and unchecked alike |
| Logging | `ILogger.LogInformation` / `LogWarning` / `LogError`, `Trace.WriteLine`, `Debug.WriteLine`, `EventSource.Write`, log-context writes (Serilog `LogContext`) | SLF4J `Logger.*`, `java.util.logging.Logger.*`, Log4j `Logger.*`, log-context writes (`MDC.put`) |
| Reflection that reads or writes | `FieldInfo.GetValue` / `SetValue`, `PropertyInfo.SetValue`, `MethodInfo.Invoke`, `Activator.CreateInstance` | `Field.get` / `set`, `Method.invoke`, `Constructor.newInstance` |
| Native interop | `[DllImport]` / `[LibraryImport]` (P/Invoke), COM calls, `Marshal.*` | JNI, JNA, the Foreign Function & Memory API (Project Panama) |
| Externally triggered callbacks | `[HttpGet]` / `[HttpPost]` handlers, `event += handler` subscriptions, timer ticks, SignalR / WebSocket callbacks, signal handlers (`PosixSignalRegistration`) | `@GetMapping` / `@PostMapping` handlers, `@RabbitListener`, `@KafkaListener`, `@JmsListener`, `@EventListener`, `@SqsListener`, `@Scheduled`, `ScheduledExecutorService` callbacks, WebSocket callbacks |
| Calls through an interface whose implementation has effects | any call through an interface whose implementation does any of the above: the static type hides the effect | the same |

---

## Problem / forces

If side effects are not named as a category, three things get much harder:

1. **Local reasoning.** A function whose result depends on hidden inputs (the clock, a cache, a singleton) can't be understood, or a bug in it reproduced, on its own: to understand the call, you have to understand the world around it. Naming the category is the first step toward separating the calls that need that world from the ones that don't. Composing functions relies on the same property: no hidden inputs or outputs [3].
2. **Testing.** A function with hidden writes changes state the test can't see. A function with hidden reads depends on state the test can't control. Either way, the test setup grows bigger than the function under test.
3. **Concurrency.** A function that shares mutable state with others can't run safely beside them without coordination; one that doesn't share, can. You can't tell which is which until effects are named.

One force pulls the other way: **convenience**. Every line-of-business function eventually does something (reads the database, writes a log, sends an event), and tracking which is which feels like overhead. This axiom doesn't ask you to stop. It only asks you to see them, and seeing is cheap once the category has a name.

---

## Why

**1. The compiler won't flag effects for you.**
Neither C#'s nor Java's type system marks effects in a signature; a `void` return is only a hint (see *Definitions*). So recognizing effects is a *reading* skill, and you can only practice it once the category has a name.

**2. Effects are how programs touch the world.**
Without side effects, a program is a mathematical function: it takes inputs, produces outputs, and changes nothing observable. Such a program is useless: it can't save a file, send a message, draw a pixel or learn the time of day. Every useful program has effects somewhere. The question, which later axioms answer, is *where*: scattered through every function, or gathered at the edges.

**3. Effects are a common source of non-local bugs.**
*Problem / forces* showed what hidden inputs cost. Hidden writes are the same problem in reverse: changing what a function does ripples into code that never calls it. As Hickey argues, mixing state into what should be plain values is a root of incidental complexity [1]. Naming the category is what lets you ask *which* effects a function has, and *which* of them could move elsewhere.

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

← Previous: [Axiom 3 — Immutability](axiom-03-immutability.md) · Next: [Axiom 5 — Impure functions](axiom-05-impure-functions.md) →
