extension Array {
    /// Returns nil if the array is empty, otherwise returns self.
    package var nilIfEmpty: [Element]? {
        isEmpty ? nil : self
    }
}
