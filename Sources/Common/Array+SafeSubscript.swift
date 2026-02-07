extension Array {
    /// Safely access array element by index, returning nil if index is out of bounds.
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
