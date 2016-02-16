import Spectre
import Silvia

func describeRoute() {
    describe("a Route with method: 'GET', pattern: [a-z]+, handler: {}, placeholders: [\"foo\"]") {
        let route = Route("GET", pattern: "/test", handler: "foo", placeholders: ["foo"]) 

        $0.it("has an attribute 'method' => 'GET'") {
            try expect(route.method) == "GET"
        }

        $0.it("has an attribute 'pattern' => '/test'") {
            try expect(route.pattern) == "/test"
        }

        $0.it("has an attribute 'placeholders' => [\"foo\"]") {
            try expect(route.placeholders.count) == 1
            try expect(route.placeholders.contains("foo")).to.beTrue()
        }

        $0.it("matches '/test'") {
            try expect(route.matches("/test")).to.beTrue()
        }
    }
}