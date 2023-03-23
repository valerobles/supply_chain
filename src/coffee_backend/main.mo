import Principal "mo:base/Principal";

shared(message) actor class Main(){
  var x = "";
  public  query func greet() : async Text {
    x := x#"test" #Principal.toText(message.caller);
    return "Hello, " # x # "!";
  };
  public  func extend() :async(){
     x := x#"test" #Principal.toText(message.caller);
  };
  
};
