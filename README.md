![Impeller: A Distributed Value Store in Swift](https://image.png)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Impeller is a Distributed Value Store (DVS) written in Swift. It was inspired by successful Distributed Version Control Systems (DVCSes) like Git and Mercurial, and appropriates their design and terminology for use with application data, rather than source code files.

With Impeller, you compose a data model from Swift value types (structs), and persist them locally in a store like SQlite. Values can be _pushed_ to services like CloudKit, and _pulled_ down to other devices, to facilitate sync across devices, and with web apps.

At this juncture, Impeller is largely experimental. It evolves rapidly, and — much like Swift itself — there is no attempt made to sustain backward compatibility. It is not currently recommended for production quality projects.

## Objectives

Impeller was inspired by the notion that a persisent store, in the vein of Core Data or Realm, could be based on value types, rather than the usual reference types (classes). Additionally, such a store could be designed from day one to work globally, across devices, much like a DVCS like Git.

Value types like structs and enums play an important role in Swift development, and have a number of advantages over classes for model data. Because they are generally stored in stack memory, they don't incur the cost of allocation and deallocation associated with heap memory. They also do not have to be garbage collected or reference counted, which adds to the performance benefits.

Perhaps even more important than performance, value types offer greater safety guarantees than mutable reference types like objects. Because each value gets copied when passed into a function or assigned to a variable, each copy can be treated in isolation, and the risk of race conditions and other concurrency issues is greatly reduced. The ability of a developer to reason about a value is also greatly enhanced when there is a guarantee it will not be modified via a different scope.

While the initial objective for Impeller is to develop a working value store that syncs, the longer term goal is much more ambitious: Impeller should evolve into an abstraction that can push and pull values from a wide variety of backends (_e.g_ CloudKit, SQL databases), and populate arbitrary frontend modelling frameworks (_e.g._ Core Data, Realm). In effect, middleware that couples any supported client framework with any supported cloud service. 

If realized, this would facilitate much simpler migration between services and frameworks, as well as hetereogenous combinations which currently require a large investment of time and effort to realize. For example, imagine an iOS app based on Core Data syncing automatically with Apple's CloudKit, which in turn exchanges data with an Android app utilizing a SQlite model.

## Installation

### Requirements
Impeller is currently only available for iOS. It is a Swift module, requiring Swift 3.

### Carthage

Add Impeller to your Cartfile to have it installed by Carthage.

github "mentalfaculty/impeller" ~> 0.1

Build using `carthage update`, and drag `Impeller.framework` into Xcode.

### Manual

To install Impeller manually

1. Drag the `Impeller.xcodeproj` into your Xcode project.
2. Select your project's _Target_, and open the _General_ tab.
3. Click the _+_ button in the _Embedded Binaries_ section, and choose `Impeller.framework`.


### Examples
Examples of usage are included in the _Examples_ directory. The _Listless_ project is a good place to begin. It is a simple iPhone task management app which syncs via CloudKit.

Other examples of usage can be found in the various _Tests_ folders.

## Usage

### Making a Model
Unlike most data modelling frameworks (_e.g._ Core Data), Impeller is based on value types (structs). There is no modeling tool, or model file; you simply create your structs.

#### Storable Protocol
You need to make your structs conform to the `Storable` protocol.

    struct Task: Storable {

The `Storable` protocol looks like this.

    public protocol Storable {
        var metadata: Metadata { get set }
        static var storedType: StoredType { get }
    
        init?(readingFrom repository:ReadRepository)
        mutating func write(in repository:WriteRepository)
    }

#### Metadata
You new type must supply a protocol for metadata storage, and a `static` property that provides a string representing the type of the struct (usually just the `struct` name).

     struct Task: Storable {
        static var storedType: StoredType { return "Task" }
        var metadata = Metadata()

The `metadata` property is used internally by the framework, and you should generally refrain from modifying it. 

One exception to this rule is the `uniqueIdentifier`, which is a global identifier for your value, and is used to store it and fetch it from repositories (persistent stores and cloud storage). By default, a _UUID_ will be generated for new values, but you can override this and set metdata with a carefully chosen `uniqueIdentifier`. You might do this in order to make shared values that appear on all devices, such as with a global settings struct. Setting a custom `uniqueIdentifer` is analogous to creating a singleton in your app.

#### Properties
The properties of your `struct` can be anything supported by Swift. Properties are not persisted to a repository by default, so you can include properties that you don't wish to have stored.

     struct Task: Storable {
        ...
         
        var text = ""
        var tagList = TagList()
        var isComplete = false

#### Loading Data
You save and load data with Impeller in much the same way you do when using the `NSCoding` protocol included in the `Foundation` framework. You need to implement

1. An initializer which creates a new struct value from data that is loaded from a repository.
2. A function to write the `struct` data into a repository for saving.

The initializer might look like this

        init?(readingFrom repository:ReadRepository) {
            text = repository.read("text")!
            tagList = repository.read("tagList")!
            isComplete = repository.read("isComplete")!
        }

The keys passed in are conventionally named the same as your properties, but this is not a necessity. You might find it useful to create an `enum` with `String` raw values to define these keys, rather than using literal values.

#### Which Data Types are Supported?
The `ReadRepository` protocol provides methods to read a variety of data types, including

- Primitive built-in types like `Int`, `Float`, `String`, and `Data`
- Optional variants of primitive types (_e.g._ `Int?`)
- Arrays of simple built-in types (_e.g._ `[Float]`)
- Other `Storable` types (_e.g._ `TagList`, where `TagList` is a `struct` conforming to `Storable`)
- Optional variants of `Storable` types (_e.g._ `TagList?`)
- Arrays of `Storable` types (_e.g._ `[TagList]`)

These types are the only ones supported by repositories, but this does not mean your `struct`s cannot include other types. You simply convert to and from these primitive types when storing and loading data, just as you do when using `NSCoding`.

#### Storing Data
The function for storing data into a repository makes use of methods in the `WriteRepository` repository.

        mutating func write(in repository:WriteRepository) {
            repository.write(text, for: "text")
            repository.write(&tagList, for: "tagList")
            repository.write(isComplete, for: "isComplete")
        }

This is the inverse of loading data, so the keys used must correspond to the keys used in the initializer above.

### Repositories
Places where data gets stored are referred to as _repositories_, in keeping with the terminology of DVCSes. This also emphasizes the distributed nature of the framework, with repositories spread across devices, and in the cloud. 

#### Creating a Repository
Each repository type has a different setup. Typically, you simply initialize the repository, and store it in an instance variable on a controller object.

    let localRepository = MemoryRepository()

#### Storing Changes
There is no central managing object in Impeller, like the `NSManagedObjectContext` of Core Data. Instead, when you want to save a `Storable` type, you simply ask the repository to commit it.

    localRepository.commit(&task)

Note that the `commit` function takes an `inout` parameter, meaning you must pass in a variable, not a constant. The reason for this is that when storing into a repository, the metadata of the stored types (_e.g._ timestamps) get updated to mirror the latest state in the repository.

### The Exchange
You can use Impeller as a local store, but most modern apps need to sync data across devices, or with the cloud. You can couple two or more repositories using an _Exchange_.

#### Creating an Exchange
Like the repositories, you usually create an _Exchange_ just after your app launches, and you have created all repositories. You could also do it using a lazy property, like this

    lazy var exchange: Exchange = { 
        Exchange(coupling: [self.localRepository, self.cloudRepository], pathForSavedState: nil) 
    }()

#### Exchanging Data
To trigger an exchange of the recent changes between repositories, simply call the `exchange` function.

        exchange.exchange { error in            
            if let error = error {
                print("Error during exchange: \(error)")
            }
            else {
                // Refresh UI here
            }
        }

The `exchange` function is asynchronous, with a completion callback.

### Merging
When committing changes to a repository, it is possible that the repository value has been changed by another commit or exchange since the value was originally fetched. It is important to detect this eventuality, so that changes are not overwritten by the stale values in memory. There are plans to offer powerful merging in future, but at the moment only very primitive support is available.

You can implement 

    func resolvedValue(forConflictWith newValue:Storable, context: Any?) -> Self

from the `Storable` protocol in your `struct`. By default, this function returns `self`, so that the values currently in memory take precedence. You can override that behavior to return a different `struct` value, which will be what gets stored in the repository.

### Gotchas
A value store is quite a different beast to a store based on reference types (_e.g._ Core Data). Some aspects become more straightforward when using values (_e.g._ passing values between threads), but other behaviors may surprise you at first. This section covers a few of the more major differences.


#### Advantages of Value Types
In addition to the unexpected behaviors that come with using value types, there are a number of welcome surprises. Here are a few of the advantages of using a value store:

- Value types are often stored on the stack, and don't incur the cost of heap allocation and deallocation
- There is no need for reference counting or garbage collection, making cleanup much faster
- Value types are copied when assigned or passed to a function, making data sharing much less likely
- Value types can be passed between threads with little risk, because each thread gets a separate copy

#### Uniquing
Uniquing

#### Relationship Cycles

#### Copying Sub-Values
Copying a sub-value does not copy the stored data

#### Recursive Trees


## Progress

### State of the Union

### Imminent Projects
