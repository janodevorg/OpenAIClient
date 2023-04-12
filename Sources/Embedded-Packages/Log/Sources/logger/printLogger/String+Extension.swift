extension String
{
    /**
      Resize string to `newLength`.

      - If resulting string is bigger it pads left with spaces.
      - If string is bigger truncates but adds `…` as last character.
    */
    func resizeString(newLength: UInt) -> String {
        guard newLength > 0 else { return "" }
        return count < newLength
            ? padLeft(newLength: Int(newLength))
            : truncatedWithEllipsis(newLength: Int(newLength))
    }

    /**
      Truncates string to `newLength`.
      If the resulting string is smaller, the last character is `…`.
    */
    func truncatedWithEllipsis(newLength: Int) -> String {
        guard newLength > 0 else { return "" }
        guard !isEmpty else { return self }
        return count <= newLength ? self : prefix(newLength - 1) + "…"
    }

    /// Pads left if string is less than newLength. Otherwise returns the same string.
    func padLeft(newLength: Int, withPad character: Character = " ") -> String {
        newLength > count
            ? String(repeatElement(character, count: newLength - count)) + self
            : self
    }
}
