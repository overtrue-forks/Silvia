import Spectre
import Silvia

func describeRouter() {
    describe("a router") {
        $0.it("add Route:GET /user/profile") {
            Router.get("/user/profile", handler: "handler")
            
            let (simple, dynamic) = Router.routes()

            try expect(simple.keys.contains("GET")).to.beTrue()
            try expect(dynamic.count) == 0
            
            let routes = simple["GET"]!

            try expect(routes.count) == 1
            try expect(routes.keys.contains("/user/profile")).to.beTrue()
            try expect(routes["/user/profile"]!.handler as? String) == "handler"
        }

        $0.it("add Route:POST /user/{name}[/{id:\\d+}/{category}]") {
            Router.post("/user/{name}[/{id:\\d+}/{category}]", handler: "test")
            
            let (_, dynamic) = Router.routes()

            try expect(dynamic.keys.contains("POST")).to.beTrue()

            let routes = dynamic["POST"]!
            try expect(routes.count) == 1
            try expect(routes.keys.contains("^(?:/user/([^/]+)|/user/([^/]+)/(\\d+)/([^/]+))$")).to.beTrue()
        }
        
        $0.it("dispatch: GET /user/profile will be found with Route.pattern: /user/profile") {
            if let route = Router.dispatch("GET", uri: "/user/profile") {
                try expect(route.handler as? String) == "handler"
                try expect(route.args.count) == 0    
            } else {
                throw failure("is broken.")
            }
        }

        $0.it("dispatch: GET /user/overtrue will be NOT found") {
            if let _ = Router.dispatch("GET", uri: "/user/overtrue") {
                throw failure("is broken.")
            }
        }

        $0.it("dispatch: POST /user/overtrue will be found") {
            if let route = Router.dispatch("POST", uri: "/user/overtrue") {
                try expect(route.handler as? String) == "test"
                try expect(route.args.keys.contains("name")).to.beTrue()
                try expect(route.args["name"]) == "overtrue"
            } else {
                throw failure("is broken.")
            }
        }

        $0.it("dispatch: POST /user/overtrue/56/comment will be found") {
            if let route = Router.dispatch("POST", uri: "/user/overtrue/56/comment") {
                try expect(route.handler as? String) == "test"
                try expect(route.args.count) == 3
                try expect(route.args.keys.contains("name")).to.beTrue()
                try expect(route.args.keys.contains("id")).to.beTrue()
                try expect(route.args.keys.contains("category")).to.beTrue()
                try expect(route.args["name"]) == "overtrue"
                try expect(route.args["id"]) == "56"
                try expect(route.args["category"]) == "comment"
            } else {
                throw failure("is broken.")
            }
        }

        $0.it("will success handle the route: /test/{param:\\d+}") {
            Router.get("/test/{param:\\d+}", handler: "foobar") 

            if let route = Router.dispatch("GET", uri: "/test/234566") {
                try expect(route.handler as? String) == "foobar"
                try expect(route.args.keys.contains("param")).to.beTrue()
                try expect(route.args["param"]) == "234566"
            } else {
                throw failure("is broken.")
            }
        }

        $0.it("will success handle the route: /te{ param }st") {
            Router.get("/te{ param }st", handler: "foobar") 

            if let route = Router.dispatch("GET", uri: "/teabcst") {
                try expect(route.handler as? String) == "foobar"
                try expect(route.args.keys.contains("param")).to.beTrue()
                try expect(route.args["param"]) == "abc"
            } else {
                throw failure("is broken.")
            }
        }

        $0.it("will success handle the route: /test/{param1}/test2/{param2}") {
            Router.get("/test/{param1}/test2/{param2}", handler: "foobar3") 
            
            if let route = Router.dispatch("GET", uri: "/test/a23/test2/67") {
                try expect(route.handler as? String) == "foobar3"
                try expect(route.args.keys.contains("param1")).to.beTrue()
                try expect(route.args.keys.contains("param2")).to.beTrue()
                try expect(route.args["param1"]) == "a23"
                try expect(route.args["param2"]) == "67"
            } else {
                throw failure("is broken.")
            }
        }
    }
}