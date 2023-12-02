using System;
using System.Collections.Generic;
using System.Linq;
using HotChocolate.Types;

// Define your GraphQL types
public class Property
{
    public string Id { get; set; }
    public string Name { get; set; }
    public DateTime Date { get; set; }
    // Add other fields as needed
}

// Input type for DateTime range
public class DateTimeRangeInput
{
    public DateTime Start { get; set; }
    public DateTime End { get; set; }
}

// Input type for property filtering
public class PropertyFilterInput
{
    public DateTimeRangeInput Date { get; set; }
}

// GraphQL Query type
public class Query
{
    [UseFiltering]
    [ExtendDirective(Name = "where", On = DirectiveLocation.FIELD)]
    public IEnumerable<Property> GetProperties([Service] IEnumerable<Property> properties, PropertyFilterInput filter)
    {
        // Filtering logic is handled by the UseFiltering attribute
        return properties;
    }
}

// Custom directive for extending the where directive
public class DateRangeDirectiveType : DirectiveType
{
    protected override void Configure(IDirectiveTypeDescriptor descriptor)
    {
        descriptor.Name("dateRange");
        descriptor.Location(DirectiveLocation.ArgumentDefinition);
        descriptor.Argument("start", a => a.Type<NonNullType<DateTimeType>>());
        descriptor.Argument("end", a => a.Type<NonNullType<DateTimeType>>());
        descriptor.Use(next => async context =>
        {
            var start = context.Argument<DateTime>("start");
            var end = context.Argument<DateTime>("end");

            // Perform filtering based on the date range
            var queryable = context.GetSource<IEnumerable<Property>>().AsQueryable();
            queryable = queryable.Where(property => property.Date >= start && property.Date <= end);

            context.SetSource(await queryable.ToListAsync());
            await next(context);
        });
    }
}

// Main program entry point
class Program
{
    static void Main(string[] args)
    {
        // Replace this with your actual data source
        var propertiesData = new List<Property>
        {
            new Property { Id = "1", Name = "Property A", Date = new DateTime(2023, 2, 15, 12, 0, 0) },
            new Property { Id = "2", Name = "Property B", Date = new DateTime(2023, 5, 20, 18, 30, 0) },
            // Add more properties as needed
        };

        // Configure HotChocolate server
        var server = new HotChocolate.AspNetCore.Server.ApplicationServiceCollectionExtensions
            .RequestExecutorBuilder()
            .AddQueryType<Query>()
            .AddType<PropertyFilterInputType>()
            .AddDirectiveType<DateRangeDirectiveType>()
            .Create();

        // Start the server
        server.ExecuteRequestAsync("{ properties(where: { date: { start: \"2023-01-01T00:00:00Z\", end: \"2023-12-31T23:59:59Z\" } }) { id name date } }")
            .GetAwaiter()
            .GetResult();
    }
}
