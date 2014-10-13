var IDOLExtensionClass = function() {};

IDOLExtensionClass.prototype = {
    run: function(arguments) {
        arguments.completionFunction({"content" : document.body.innerHTML,
                                      "url"     : document.baseURI});
    },
        
    finalize: function(arguments) {
        document.body.innerHTML = arguments["content"];
    }
};

var ExtensionPreprocessingJS = new IDOLExtensionClass;