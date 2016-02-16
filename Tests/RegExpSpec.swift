import Spectre
import Silvia

func describeRegExp() {
    describe("a regex: '[a-z]+'") {
        let regex = try! RegExp("[a-z]+")

        $0.it("is matching 'hello'") {
            try expect(regex.isMatching("hello")).to.beTrue()
        }

        $0.it("is matching 'hello world!'") {
            try expect(regex.isMatching("hello world!")).to.beTrue()
        }

        $0.it("not match '1234'") {
            try expect(regex.isMatching("1234")).to.beFalse()
        }

        $0.it("not match '$%^'") {
            try expect(regex.isMatching("$%^")).to.beFalse()
        }
    }

    describe("a regex: '^[a-z]+$'") {
        let regex = try! RegExp("^[a-z]+$")

        $0.it("is matching 'hello'") {
            try expect(regex.isMatching("hello")).to.beTrue()
        }

        $0.it("not matching '1234hello'") {
            try expect(regex.isMatching("1234hello")).to.beFalse()
        }

        $0.it("not matching 'hello1234'") {
            try expect(regex.isMatching("hello1234")).to.beFalse()
        }
    }

    describe("a regex: '[a-z0-9]+'") {
        let regex = try! RegExp("[a-z0-9]+")

        $0.it("match 'abc234*_', result is 'abc234'") {
            try expect(regex.match("abc234*_")) == "abc234"
        }

        $0.it("match 'abc234*_foobar', result is 'abc234'") {
            try expect(regex.match("abc234*_foobar")) == "abc234"
        }

        $0.it("match '_#$%', result is nil") {
            try expect(regex.match("_#$%")).to.beNil()
        }
    }

    describe("a regex: '[a-z0-9]+'") {
        let regex = try! RegExp("[a-z0-9]+") 

        $0.it("matchs all the string 'foo1234_bar456' return [\"foo1234\", \"bar456\"]") {
            let matches = regex.allMatches("foo1234_bar456")

            try expect(matches.count) == 2
            try expect(matches.first) == "foo1234"
            try expect(matches.last) == "bar456"
        }
    }
}