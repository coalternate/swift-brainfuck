// This file (and the enclosing folder) defines custom functions and structs and whatnot
// whose usage shouldn't necessarily be limited to the scope of this package.

// Eventually this will be a package in its own right, but for now it's more convenient
// to keep it here.

public extension Array { func cleared() -> [Element] { return Array<Element>() } }
