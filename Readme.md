Sorted Array
------------

`TRISortedArray` is **partialy mutable** `NSArray` subclass, that always keeps the contents sorted using given sort descriptors.

```objc
TRISortedArray *array = [TRISortedArray new];
array.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ];

[array addObject:@"Daniel"]; // Daniel
[array addObject:@"Bob"];    // Bob, Daniel
[array addObject:@"Adam"];   // Adam, Bob, Daniel
[array addObject:@"Eve"];    // Adam, Bob, Daniel, Eve
[array addObject:@"Clark"];  // Adam, Bob, Clark, Daniel, Eve
[array removeObject:@"Bob"]; // Adam, Clark, Daniel, Eve

array.isReversed = YES;      // Eve, Daniel, Clark, Adam
```

All methods available on `NSArray` work on `TRISortedArray` too, so you have no problem creating, accessing or enumerating the contents. In addition, it provides these capabilities:

  - **Sort Descriptors** – Set an array of `NSSortDescriptor` objects and change it at any time. The objects are immediatelly re-sorted.
  - **Concurrency** – Optionally, the sorting can be done concurrently.
  - **Reversing** – Easily reverse order without changing the sort descriptors.
  - **Adding** – Objects are inserted at appropriate indexes, so sort order is not broken.
  - **Removing** & **Filtering** – Removing is not limited in any way, since it doesn’t break sort order.
  - **Live Updating** – The array uses KVO to update order of the objects. Observed keys are taken from the sort descriptors.
  - **Observing** – Since the objects may change indexes at any time, `TRISortedArray` supports registering multiple observers that are notified of all changes.


### Observing Changes

There are two ways to react on changes to the array order:

  - **Observer** implementing protocol – Your object can implement provided `TRISortedArrayObserver` protocol (fully or partially) and register itself by calling `-addObserver:` on the array. This object is notified about every single change (insertion/removal/move), which is suitable to be used with `UITableView`.
  - Subscription **Block** – You can register a block to be invoked whenever the array contents changes in some way. This block does not know what exactly changed and in what way.

Changes to the content are coalesced into _groups_. For example, adding 3 objects from other array by calling `-addObjectsFromCollection:` will report following:

  - Observers implementing protocol:
    1. _Begin Changes_
    2. _Will/Did Insert Object At Index_
    3. _Will/Did Insert Object At Index_
    4. _Will/Did Insert Object At Index_
    5. _End Changes_
  - Subscription blocks: only invoked **once** per _group_ – at the moment of _End Changes_.


### Live Updating

The true magic of this class is in observing all key-paths on which the sort descriptors depend. Any time you change a property of an object, all Sorted Arrays that use the property are updated.

```objc
TRISortedArray *array = [TRISortedArray new];
array.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES] ];

MYPerson *smith = [MYPerson first:@"Adam" last:@"Smith"];
MYPerson *jones = [MYPerson first:@"Bob" last:@"Jones"];
MYPerson *taylor = [MYPerson first:@"Clark" last:@"Taylor"];

[array setObjects:@[taylor, smith, jones]]; // Adam Smith, Bob Jones, Clark Taylor

smith.firstName = @"Daniel"; // Bob Jones, Clark Taylor, Daniel Smith
taylor.firstName = @"Eve"; // Bob Jones, Daniel Smith, Eve Taylor
```

For every `.firstName` change in the example these events are reported:

  - Observers using protocol:
    1. _Begin Changes_
    2. _Will Move Object From Index_
    3. _Did Move Object From Index To Index_
    4. _End Changes_
  - Subscription blocks: invoked after every change.
