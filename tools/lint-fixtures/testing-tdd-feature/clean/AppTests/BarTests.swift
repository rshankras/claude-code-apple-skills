import Testing

@Suite struct BarTests {
    @Test func example() {
        #expect(1 + 1 == 2)
    }
}
