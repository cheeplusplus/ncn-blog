---
title: The Muftec Fabricator
tags: muftec,coding,csharp,compilers
date: July 27, 2014
---
Something I’d been planning on writing since the start of the project, the [Fabricator](https://github.com/cheeplusplus/muftec/blob/master/Muftec/Fabricator.cs) is a surprisingly small (~222 sloc) class that takes the lexer output and converts a MUF script into an executable MSIL application. (It’s actually a compiler, but it’s called the Fabricator because the lexer is called the Compiler and I really need to fix their names)

In order to achieve this, where the normal runtime executes code by lexing the source, putting tokens on either the execution queue or the runtime stack, then starting to run commands in the execution queue, instead the Fabricator translates the execution queue directly into MSIL commands. Commands and stack inserts are still run in the same order, but functions are called directly instead of performing the lookup at runtime, resulting in what should be the most efficient code without Muftec stack items to being native CLR types on the stack.

In effect, a MUF program turns from

```
: main
    2 2 + print
;
```

into (C# for readibility)

```
public static void func_main(RuntimeStack stack) {
    stack.Push(new MuftecStackItem(2)); // 2
    stack.Push(new MuftecStackItem(2)); // 2 2
    BCL.Math.Add(stack); // 4
    BCL.IO.Print(stack); // Prints '4'
}
```

Now the application can be optimized (as much is possible with this exeuction mode).

Optimally, we’d use native CLR types like int and string instead of wrapping them in a MuftecStackItem, but doing so would mean we need to dynamically generate MSIL functions instead of doing the normal execution stack flow. I think this is certainly an alternative, but I wanted to get a MSIL compiler up and running in the simplest form possible without sacrificing the rest of the project, especially since the execution mode is a lot easier to debug.

There are a couple components needed to write new applications in MSIL. The first is provided by the .NET framework reflection tools as the ability to create a new Assembly, Class, and Methods through code. Once you’ve created a method, you can Emit IL into the method. Normally you would accomplish this with the Emit class which involves calling functions to add MSIL bytecode manually.

Instead of using the baseline IL Emit, I chose to use a project I came across called [Sigil](https://github.com/kevin-montrose/Sigil). This allows me to write IL instructions more cleanly, for example:

In Sigil, calling 2 + 2 and printing would be:

```
var funcDef = Emit<Action>.NewDynamicMethod("Add");
funcDef.LoadConstant(2); // Put the int 2 on the stack
funcDef.LoadConstant(2);
funcDef.Add(); // Adds two numbers together
funcDef.Call(typeof(Console).GetMethod("WriteLine", new[] { typeof(object) }); // Get the Console.WriteLine method and call it
funcDef.Return(); // All methods must return
var del = funcDef.CreateDelegate(); // Compile the IL and turn this into a real usable delegate
del(); // Execute the method we just created
```

where as doing this with IL Emit would be:

```
var funcDef = new DynamicMethod("Add", /* some other stuff */);
var il = funcDef.GetILGenerator();
il.Emit(OpCodes.Ldc_i4, 2); // Put the int 2 on the stack
il.Emit(OpCodes.Ldc_i4, 2);
il.Emit(OpCodes.Add);
il.Emit(OpCodes.Call, typeof(Console).GetMethod("WriteLine", new[] { typeof(object) })); // Get the Console.WriteLine method and call it
var del = (Action) funcDef.CreateDelegate(typeof(Action));
```

It’s very similar, but requires knowledge of specific opcodes, whereas Sigil provides several conveniences especially including compile type sanity checking (like knowing a function takes 2 arguments but only 1 is on the stack) which helps a lot when learning how to use it.

An interesting way to look at how this works is the fact that the GenerateInnerFunction method of the Fabricator is actually doing exactly what the [Run method](https://github.com/cheeplusplus/muftec/blob/4290fe92f95929f034a294ae049e320c7c6fa0bb/MuftecLib/MuftecLibSystem.cs#L233) of the MuftecLibSystem does. That class actually performs execution, whereas this class pretends it’s executing the application but writes IL to do it instead. In the Fabricator, however, instead of jumping into a new stack when we move to a user defined function, we’re actually writing a real .NET function that we call, so instead of being recursive, we just execute that defined method instead, which simplifies execution flow a bit as well. This also required me to create function definitions before defining their contents, sort of like declaring headers in C, since they can’t be called if they don’t exist.

I haven’t yet done performance testing, but despite still needing a runtime stack, the lack of an execution stack, not needing to resolve function or opcodes by name at runtime, and other optimizations should make this method a lot faster. There are still a few ways to improve performance even further, especially if I make the whole system run off dynamically generated methods instead.

I have a few things left I need to do with Muftec at this point. Primarily I need to finish writing all of the opcodes, as I want as much parity with Fuzzball (the source of our implementation) as possible, and also need to add some other basic features like loops. If-else statements are supported, but not much else.
