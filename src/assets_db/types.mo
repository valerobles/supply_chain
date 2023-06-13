

 type HeaderField = (Text, Text);

     type Chunk = {
        batch_name : Text;
        content  : [Nat8];
    };

      type Asset = {
        encoding: AssetEncoding;
        content_type: Text;
    };

     type AssetEncoding = {
        modified       : Int;
        content_chunks : [[Nat8]]; 
        total_length   : Nat;
        certified      : Bool;
    };

     type HttpRequest = {
        url : Text;
        method : Text;
        body : [Nat8];
        headers : [HeaderField];
    };

     type HttpResponse = {
        body : [Nat8];
        headers : [HeaderField];
        status_code : Nat16;
        streaming_strategy : ?StreamingStrategy;
    };

     type StreamingStrategy = {
        #Callback : {
            token : StreamingCallbackToken;
            callback : shared () -> async ();
        };
    };

     type StreamingCallbackToken = {
        key : Text;
        index : Nat;
        content_encoding : Text;
    };

     type StreamingCallbackHttpResponse = {
        body : [Nat8];
        token: ?StreamingCallbackToken;
    };

