//
//  IDOLService.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 11/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation

import CoreData

// Central class for carrying out communication with HP IDOL OnDemand webservices
// Designed as a singleton.
// Completely uses async requests

public class IDOLService {
    
    // MARK: Inner Class and Structs
    public class var sharedInstance : IDOLService {
        struct Singleton {
            static let instance = IDOLService()
        }
        return Singleton.instance
    }
    
    // URL strings for various IDOL services
    private struct _URLS {
        static let baseURL          = "https://api.idolondemand.com/1"
        static let asyncSvc         = baseURL + "/api/async"
        static let listIndexUrl     = asyncSvc + "/listindexes/v1?apikey="
        static let addToIndexUrl    = asyncSvc + "/addtotextindex/v1"
        static let findSimilarUrl   = asyncSvc + "/findsimilar/v1"
        static let querytextindex   = asyncSvc + "/querytextindex/v1"
        static let viewDocument     = asyncSvc + "/viewdocument/v1"
        static let getContent       = asyncSvc + "/getcontent/v1"
        static let deleteFromIndex  = asyncSvc + "/deletefromtextindex/v1"
        static let jobResult        = baseURL + "/job/result/"
    }
    
    struct ErrCodes {
        static let ErrUnknown           = -10000
        static let ErrAPIKeyNotFound    = -10001
        static let ErrMethodFailed      = -10002
        static let ErrAPIKeyInvalid     = -10003
    }
    
    // For HTTP parameter boundary
    private let Boundary = "---------------------------" + NSUUID().UUIDString
    
    // MARK: - IDOL Service
    // Method to invoke List Index service and get back the results to caller in a completion handler
    
    public func fetchIndexList(apiKey:String, completionHandler handler: TypeAliases.ResponseHandler?) {
        let reqUrl = _URLS.listIndexUrl + apiKey
        apiInvoke(apiKey, reqUrl: reqUrl, completionHandler: handler)
    }
    
    // Method to invoke Query Text Index service and get back the results to caller in a completion handler
    public func queryTextIndex(apiKey:String, text:String, index:String, searchParams : [String:String], completionHandler handler: TypeAliases.ResponseHandler?) {
        let reqUrl = _URLS.querytextindex + "?apikey=" + apiKey +
                     queryParams([Constants.TextParam:text,Constants.IndexesParam:index]) +
                     queryParams(searchParams)
        
        apiInvoke(apiKey, reqUrl: reqUrl, completionHandler: handler)
    }
    
    // Method to get the contents of a document.
    public func viewDocument(apiKey:String, url:String, completionHandler handler: TypeAliases.ResponseHandler?) {
        let reqUrl = _URLS.viewDocument + "?apiKey=" + apiKey + queryParams([Constants.UrlParam:url])
        apiInvoke(apiKey, reqUrl: reqUrl, completionHandler: handler)
    }
    
    public func getContent(apiKey:String, reference:String, index:String, completionHandler handler: TypeAliases.ResponseHandler?) {
        let reqUrl = _URLS.getContent + "?apiKey=" + apiKey + queryParams([Constants.IndexesParam:index,
                                                                            Constants.IndexReferenceParam:reference,
                                                                            Constants.PrintFieldParam:Constants.PrintFieldDate])
        apiInvoke(apiKey, reqUrl: reqUrl, completionHandler: handler)
    }
    
    public func listDocuments(apiKey:String, index:String, completionHandler handler: TypeAliases.ResponseHandler?) {
        return queryTextIndex(apiKey, text: "*", index: index, searchParams: [Constants.MaxResultParam:Constants.MaxResultsPerIndex], completionHandler: handler)
    }

    // Method to upload documents to an IDOL index using the Add to Index service
    public func addToIndexFiles(apiKey:String, dirPath : String, indexName: String, completionHandler handler: TypeAliases.ResponseHandler?) {
        
        // First get file meta info
        let fileMeta = self.getFileMeta(dirPath)
        
        // Then create an HTTP POST request containing file data
        let postRequest = self.createAddIndexRequest(fileMeta, idolPath: nil, indexName: indexName, apiKey: apiKey)
        
        apiInvoke(apiKey, request: postRequest, completionHandler: handler)
    }
    
    // Method to upload a file to an IDOL index using the Add to Index service. For local files we assign a reference starting with idol://
    public func addToIndexFile(apiKey:String, filePath : String, indexName : String, completionHandler handler: TypeAliases.ResponseHandler?) {
        let fileMeta = (filePath,filePath.lastPathComponent,false)
        
        let idolPath = "idol://" + indexName + "/" + fileMeta.1
        
        let postRequest = self.createAddIndexRequest([fileMeta], idolPath: idolPath, indexName: indexName, apiKey: apiKey)
        
        apiInvoke(apiKey, request: postRequest, completionHandler: handler)
    }
    
    // Method to add a document to index when a publically accessible url is provided
    public func addToIndexUrl(apiKey:String, url:String, index:String, completionHandler handler: TypeAliases.ResponseHandler?) {
        
        let additional_metadata = modifyDateTitle(url.lastPathComponent)
        
        let reqUrl = _URLS.addToIndexUrl + "?apikey=" + apiKey +
                     queryParams([Constants.UrlParam:url,Constants.IndexParam:index,Constants.AdditionaMetaParam:additional_metadata])
        
        apiInvoke(apiKey, reqUrl: reqUrl, completionHandler: handler)
    }
    
    // Method to delete a document from an index
    public func deleteFromIndex(apiKey:String, reference:String, index:String, completionHandler handler: TypeAliases.ResponseHandler?) {
        let reqUrl = _URLS.deleteFromIndex + "?apikey=" + apiKey +
                     queryParams([Constants.IndexParam : index, Constants.IndexReferenceParam : reference])
        
        apiInvoke(apiKey, reqUrl: reqUrl, completionHandler: handler)
    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a keyword term
    public func findSimilarDocs(apiKey:String, text: String, indexName: String, searchParams : [String:String], completionHandler handler: TypeAliases.ResponseHandler?) {
        
        // For keyword term search, we make use of HTTP GET request
        var urlStr = _URLS.findSimilarUrl + "?apikey=" + apiKey +
                     queryParams([Constants.TextParam:text,Constants.IndexesParam:indexName]) +
                     queryParams(searchParams)
        
        NSLog("findSimilarDocs: text=%@, indexName=%@",text,indexName)
        apiInvoke(apiKey, reqUrl: urlStr, completionHandler: handler)
    }

    // Method to invoke IDOL Find Similar Documents API when user has provided a url
    public func findSimilarDocsUrl(apiKey:String, url: String, indexName: String, searchParams : [String:String], completionHandler handler: TypeAliases.ResponseHandler?) {
    
        // For keyword term search, we make use of HTTP GET request
        var urlStr = _URLS.findSimilarUrl + "?apikey=" + apiKey +
                    queryParams([Constants.UrlParam:url,Constants.IndexesParam:indexName]) +
                    queryParams(searchParams)
        
        NSLog("findSimilarDocsUrl: url=%@, indexName=%@",url,indexName)
        apiInvoke(apiKey, reqUrl: urlStr, completionHandler: handler)

    }
    
    // Method to invoke IDOL Find Similar Documents API when user has provided a file
    public func findSimilarDocsFile(apiKey:String, fileName: String, indexName: String, searchParams : [String:String], completionHandler handler: TypeAliases.ResponseHandler?) {
        
        // For file requests, create a HTTP POST request
        var request = createFindSimilarFileRequest(fileName, indexName: indexName, apiKey: apiKey, searchParams: searchParams)
        
        NSLog("findSimilarDocsFile: filename=%@, indexName=%@",fileName,indexName)
        apiInvoke(apiKey, request: request, completionHandler: handler)
    }

    // MARK: Helper methods
    // MARK: Request creation and submission
    
    // Common method used by all the findSimilar* methods
    private func apiInvoke(apiKey:String, reqUrl:String, completionHandler handler: TypeAliases.ResponseHandler?) {
        let request = NSURLRequest(URL: NSURL(string: reqUrl)!)
        
        apiInvoke(apiKey, request: request, completionHandler: handler)
    }
    
    private func apiInvoke(apiKey:String, request:NSURLRequest, completionHandler handler: TypeAliases.ResponseHandler?) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            self.submitAsyncJob(request, completionHandler: { (jobId: String?,jobErr: NSError?) in
                // Then process the job result
                self.processJobResult(apiKey, jobId: jobId, jobErr: jobErr, handler: handler)
            })
        })
    }
    
    // Return a url query compliant string of the parameters and their values
    private func queryParams(params : [String:String]) -> String {
        var ret = ""
        for p in params.keys {
            ret += "&\(p)=" + encodeStr(params[p]!)
        }
        return ret
    }
    
    // Method to request for and recieve the async job result
    private func processJobResult(apiKey:String, jobId: String?, jobErr: NSError?, handler: TypeAliases.ResponseHandler?) {
        if handler != nil {
            if jobErr == nil {
                let urlStr = _URLS.jobResult + jobId! + "?apikey=" + apiKey
                let request = NSURLRequest(URL: NSURL(string: urlStr)!)
                let queue = NSOperationQueue()
                
                // Now submit for result request
                NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
                    
                    if error == nil {
                        var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves, error: nil) as NSDictionary
                        //NSLog("json=\(json)")
                        if let actions = json["actions"] as? NSArray {
                            //NSLog("actions=\(actions)")
                            for act in actions {
                                if let a  = act["errors"] as? NSArray {
                                    let code = a[0]["error"] as Int
                                    let msg = a[0]["reason"] as String
                                    return handler!(data: nil,error: self.createError(code, msg: msg))
                                } else {
                                    handler!(data: data,error: nil)
                                }
                            }
                        } else {
                            return handler!(data: nil, error: self.createError(ErrCodes.ErrUnknown, msg: "Unknown Error"))
                        }
                    } else {
                        handler!(data: nil, error: error)
                    }
                })
            } else {
                handler!(data: nil, error: jobErr)
            }
        } else {
            NSLog("processJobResult: No response handler provided. Doing nothing...")
        }
    }
    
    // Submits an async request and gets back a job id. Usually this method is chained with the processJobResult method
    private func submitAsyncJob(request : NSURLRequest, completionHandler handler: TypeAliases.JobRespHandler) {
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            
            if error == nil {
                var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                NSLog("jobId response=%@",json)
                if let jobId = json["jobID"] as? String { // Handle the jobId response
                    handler(jobId: jobId,jobError: nil)
                } else if json["details"] != nil {  // Handle the error response
                    handler(jobId: nil,jobError: self.createError(json))
                }
            } else {
                NSLog("Job submission error: %@",error)
                handler(jobId: nil,jobError: self.createError(error))
            }
            
        })
    }
    
    // Create a HTTP POST request for Find Similar service when user specifies a file
    private func createFindSimilarFileRequest(filePath: String, indexName: String, apiKey: String, searchParams : [String:String]) -> NSURLRequest {
        
        var (req, postData) = initPostRequest(apiKey, reqUrlStr: _URLS.findSimilarUrl)
        
        NSLog("Processing file=%@",filePath)
        let fileData = NSFileManager.defaultManager().contentsAtPath(filePath)
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"file\"; filename=\"\(filePath)\"\r\n"))
        postData.appendData(contentTypeData())
        postData.appendData(fileData!)
        
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(contentDispositionData("indexes"))
        postData.appendData(stringToData(indexName))
        
        for p in searchParams.keys {
            postData.appendData(paramSeparatorData(Boundary))
            postData.appendData(contentDispositionData(p))
            postData.appendData(stringToData(searchParams[p]!))
        }
        
        postData.appendData(stringToData("\r\n--\(Boundary)--\r\n"))
        
        req.HTTPBody = postData
        req.addValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        return req
    }

    // Create HTTP POST request for Add to Index service. This method iterates through a list
    // of files, reads their contents and appends to the post request. For a very large number of
    // *large size* files, this method may cause problems
    private func createAddIndexRequest(fileMeta: [TypeAliases.FileMeta], idolPath: String?, indexName: String, apiKey: String) -> NSURLRequest {
        
        let reqUrl = NSURL(string: _URLS.addToIndexUrl)
        var (req, postData) = initPostRequest(apiKey, reqUrlStr: _URLS.addToIndexUrl)
        
        // Note that we have used the full path for the filename because the reference_prefix sometimes
        // return strange error for some files
        for (path,fname,isDir) in fileMeta {
            if !isDir {
                NSLog("Processing file=%@, path=%@",fname,path)
                let reference = idolPath == nil ? path : idolPath
                let fileUrl = NSURL(string: path)
                let fileData = NSData(contentsOfURL: fileUrl!)
                postData.appendData(paramSeparatorData(Boundary))
                postData.appendData(stringToData("Content-Disposition: form-data; name=\"file\"; filename=\"\(reference!)\"\r\n"))
                postData.appendData(contentTypeData())
                postData.appendData(fileData!)
            }
        }
        
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"index\"\r\n\r\n"))
        postData.appendData(stringToData(indexName))
        
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(stringToData("Content-Disposition: form-data; name=\"additional_metadata\"\r\n\r\n"))
        postData.appendData(stringToData(modifyDate()))
        postData.appendData(stringToData("\r\n--\(Boundary)--\r\n"))
        
        req.addValue("\(postData.length)", forHTTPHeaderField: "Content-Length")
        return req
    }
    
    // Method to initialize a POST request with common fields
    private func initPostRequest(apiKey: String, reqUrlStr: String) -> (request:NSMutableURLRequest, postData: NSMutableData) {
        let reqUrl = NSURL(string: reqUrlStr)
        var req = NSMutableURLRequest(URL: reqUrl!)
        
        req.HTTPMethod = "POST"
        req.addValue("multipart/form-data; boundary=\(Boundary)", forHTTPHeaderField: "Content-Type")
        
        var postData = NSMutableData()
        
        postData.appendData(paramSeparatorData(Boundary))
        postData.appendData(contentDispositionData("apikey"))
        postData.appendData(stringToData(apiKey))
        
        req.HTTPBody = postData
        return (req, postData)
    }
    
    // MARK: Method to read directory and file info
    private func getFileMeta(dirPath: String) -> [TypeAliases.FileMeta] {
        var fileMeta : [TypeAliases.FileMeta] = []
        
        // Get all director contents. Recursively descend to subdirectories
        let dirUrl = NSURL(fileURLWithPath: dirPath, isDirectory: true)
        let dirIter = NSFileManager.defaultManager().enumeratorAtURL(dirUrl!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
        
        // Iterate through all files and get their path, name and type (dir or not) info
        while let url = dirIter!.nextObject() as? NSURL {
            var path : AnyObject? = nil
            url.getResourceValue(&path, forKey: NSURLPathKey, error: nil)
            var fname : AnyObject? = nil
            url.getResourceValue(&fname, forKey: NSURLNameKey, error: nil)
            var isDir : AnyObject? = nil
            url.getResourceValue(&isDir, forKey: NSURLIsDirectoryKey, error: nil)
            fileMeta.append((path as String,fname as String,isDir as Bool))
        }
        return fileMeta
    }
    
    // MARK: Miscellaneous methods
    
    // Encode non-URL characters to URL allowed ones
    private func encodeStr(str : String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
    
    
    // Converts a string to Data
    private func stringToData(str : String) -> NSData {
        return (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    // Returns a Data for parameter Boundary string
    private func paramSeparatorData(boundary: String) -> NSData {
        return stringToData("\r\n--\(boundary)\r\n")
    }
    
    private func contentTypeData () -> NSData {
        return stringToData("Content-Type: application/x-www-form-urlencoded\r\n\r\n")
    }
    
    private func contentDispositionData(name: String) -> NSData {
        return stringToData("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
    }
    
    private func modifyDate() -> String {
        return NSString(format: Constants.ModDateJson, Utils.dateToString(NSDate())!)
    }
    
    private func modifyDateTitle(title : String) -> String {
        return NSString(format: Constants.ModDateTitleJson, Utils.dateToString(NSDate())!, title.stringByRemovingPercentEncoding!)
    }
    
    // Create NSError instance by parsing the json response
    private func createError(json : NSDictionary) -> NSError {
        let detail = json["details"] as? NSDictionary
        
        var msg = "Unknown Error"
        if var code = json["error"] as? Int {
            if code == -1012 {
                msg = "Operation Failed.\nPossible reason: Invalid API Key"
            } else {
                if let d = detail!["reason"] as? String {
                    msg = d
                } else {
                    if let m = json["message"] as? String {
                        msg = json["message"] as String
                    } else {
                        if let r = json["reason"] as? String {
                            msg = r
                        }
                    }
                }
            }
            return createError(code, msg: msg)
        }
        
        return createError(ErrCodes.ErrUnknown, msg: msg)
    }
    
    // Special function to convert the error code -1012 to Invalid API Key response message.
    private func createError(error: NSError) -> NSError {
        if error.code == -1012 {
            return createError(error.code, msg: "Operation Failed.\nPossible reason: Invalid API Key")
        }
        
        return error
    }
    
    // Create NSError instance using an error code and message
    private func createError(code: Int, msg: String) -> NSError {
       return NSError(domain: "IDOLService", code: code, userInfo: ["Description":msg])
    }
}