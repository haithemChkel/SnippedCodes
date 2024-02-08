using System;
using System.Diagnostics;
using System.Linq;
using System.Reflection;

//   For Demonstration, we will print number starting from 1 to 100.
//   When a number is multiple of three, print “Fizz” instead of a number on the console 
//   and if multiple of five then print “Buzz” on the console.
//   For numbers which are multiple of three as well five, print “FizzBuzz” on the console
//https://dotnetfiddle.net/acBBzu#
// *********************************MAIN**************************
public class Program
{
    public static void Main()
    {

        for (int i = 1; i <= 100; i++)
        {
            Console.WriteLine(i + " - " + FizzBuzz.Run(i));
        }

        TestRunner.Run(typeof(FizzBuzzTests));
    }
}


// *********************************IMPLEMENTATION**************************
class FizzBuzz
{
    public static string Run(int i)
    {
        //TODO
        return "";
    }
}

// *********************************TESTS************************************
class FizzBuzzTests
{
    public void TEST_TODO()
    {
        //TODO
        Assert.AreEqual("", "");
    }
}

// ****************************************************************************


















































class Assert
{
    public static void AreEqual(string expected, string actual)
    {
        StackTrace stackTrace = new StackTrace();
        Console.WriteLine((expected == actual ? "OK - " : "NOK - ") + stackTrace.GetFrame(1).GetMethod().Name + string.Format(" -(expected : '{0}' - actual : '{1}')", expected, actual));
    }
}

class TestRunner
{
    public static void Run(Type type)
    {
        Console.WriteLine("Run Tests : ");

        ConstructorInfo constructor = type.GetConstructor(Type.EmptyTypes);
        object classObject = constructor.Invoke(new object[] { });

        MethodInfo[] testsMethods = type.GetMethods().Where(x => x.Name.StartsWith("TEST")).ToArray();
        foreach (var testsMethod in testsMethods)
        {
            testsMethod.Invoke(classObject, new object[] { });
        }
    }
}
