extension Array {
    /// Returns nil if the array is empty, otherwise returns self.
    public var nilIfEmpty: [Element]? {
        isEmpty ? nil : self
    }
}
