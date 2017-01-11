![Impeller: A Distributed Value Store in Swift](https://image.png)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Impeller is a Distributed Value Store (DVS) written in Swift. It was inspired by successful Distributed Version Control Systems (DVCSes) like Git and Mercurial, and appropriates their design and terminology for use with application data, rather than source code files.

With Impeller, you compose a data model from Swift value types (structs), and persist them locally in a store like SQlite. Values can be _pushed_ to services like CloudKit, and _pulled_ down to other devices, to facilitate sync across devices, and with web apps.

At this juncture, Impeller is largely experimental. It evolves rapidly, and — much like Swift itself — there is no attempt made to sustain backward compatibility. It is not currently recommended for production quality projects.

## Objectives

Impeller was inspired by the notion that a persisent store, in the vein of Core Data or Realm, could be based on value types, rather than the usual reference types (classes). Additionally, such a store could be designed from day one to work globally, across devices, much like a DVCS like Git.

Value types like structs and enums play an important role in Swift development, and have a number of advantages over classes for model data. Because they are generally stored in stack memory, they don't incur the cost of allocation and deallocation associated with heap memory. They also do not have to be garbage collected or reference counted, which adds to the performance benefits.

Perhaps even more important that performance, value types offer greater safety guarantees than mutable shared types like objects. Because each value gets copied when passed into a function, or to a background thread, each copy can be operated on in isolation, and the risk of race conditions and other concurrency issues is greatly reduced. The ability of a developer to reason about a value is also greatly enhanced when there is a guarantee it will not be modified via another scope.

While the initial objective for Impeller is to develop a working value store that syncs, the longer term goal is much more ambitious: Impeller should evolve into an abstraction that can push and pull values from a wide variety of backends (_e.g_ CloudKit, SQL databases), and populate arbitrary frontend modelling frameworks (_e.g._ Core Data, Realm). In effect, middleware that couples any supported client framework with any supported cloud service. If realized, this would facilitate much simpler migration between services and frameworks, as well as hetereogenous combinations which currently require a large investment of time and effort to realize. For example, imagine an iOS app based on Core Data syncing automatically with Apple's CloudKit, which in turn exchanges data with an Android app utilizing SQlite storage.

## Installation

### Carthage

Add Impeller to your Cartfile to have it installed by Carthage.

github "mentalfaculty/impeller" ~> 0.1

Build using `carthage update`, and drag `Impeller.framework` into Xcode.

### Manual

## Usage

### Model types

### Repositories

### The Exchange

### Merging

## Progress

### State of the Union

### Imminent Projects
