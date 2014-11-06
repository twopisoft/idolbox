//
//  Constants.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation

// Provide framework wide constants.
public struct Constants {
    
    // The Group container name. Update this when you choose a different group.
    public static let GroupContainerName   = "group.com.twopi.IDOLBox"
    
    public static let IDOLService          = "IDOLService"
    
    // Key values for storing settings
    public static let kApiKey              = "IDOL_APIKey"
    public static let kMaxResults          = "IDOL_MaxResults"
    public static let kSummaryStyle        = "IDOL_SummaryStyle"
    public static let kSortStyle           = "IDOL_SortStyle"
    public static let kSettingsPasscode    = "IDOL_SettingsPasscode"
    public static let kSettingsPasscodeVal = "IDOL_SettingsPasscodeValue"
    public static let kSearchIndexes       = "IDOL_SearchIndexes"
    public static let kAddIndex            = "IDOL_AddIndex"
    public static let kDBAccountLinked     = "IDOL_DropboxAccountLinked"
    
    // IDOL param names
    public static let ApiKeyParam          = "apikey"
    public static let IndexesParam         = "indexes"
    public static let IndexParam           = "index"
    public static let RelevanceParam       = "relevance"
    public static let SortParam            = "sort"
    public static let SummaryParam         = "summary"
    public static let MaxResultParam       = "absolute_max_results"
    public static let HighlightParam       = "highlight"
    public static let PrintFieldParam      = "print_fields"
    public static let StartTagParam        = "start_tag"
    public static let IndexReferenceParam  = "index_reference"
    public static let UrlParam             = "url"
    public static let TextParam            = "text"
    public static let AdditionaMetaParam   = "additional_metadata"
    
    // IDOL param values
    public static let SummaryStyleQuick    = "quick"
    public static let SummaryStyleContext  = "context"
    public static let SummaryStyleConcept  = "concept"
    
    public static let StartTagStyle        = "<span style='background-color:yellow; color:black'>"
    
    public static let SortStyleRelevance   = "relevance"
    public static let SortStyleDate        = "date"
    
    public static let HighlightStyleSentence           = "sentences"
    public static let HighlightStyleSummarySentence    = "summary_sentences"
    public static let HighlightStyleSummaryTerms       = "summary_terms"
    
    public static let PrintFieldDate       = "modified_date,content"
    
    // Used for adding modified_date field when adding a document to the index
    public static let ModDateJson          = "{\"modified_date\":[\"%@\"]}"
    
    // Used for adding title and modified date field when adding to index
    public static let ModDateTitleJson     = "{\"modified_date\":[\"%@\"], \"title\":\"%@\"}"
    
    // Segue identifiers.
    public static let SelectIndexSearchSegue   = "SelectIndexSearch"
    public static let SelectIndexAddSegue      = "SelectIndexAdd"
    
    public static let FindSelectIndexSegue     = "FindSelectIndex"
    
    public static let SearchResultSegue        = "SearchResult"
    
    public static let SearchResultDetailSegue  = "SearchResultDetail"
    
    public static let SelectDocSegue           = "SelectDoc"
    
    public static let DefaultSearchIndex       = "wiki_eng"
    
    public static let PersonalIndexTitle       = "Personal"
    public static let PublicIndexTitle         = "Public"
    
    public static let MaxResultsPerIndex       = "100"
    
    public static let BoxTitle                 = "Box Contents"
    public static let BoxEmptyTitle            = "Box is Empty"
    
    public static let WsLinkerUrl              = "https://wslinker.herokuapp.com/readability?url="
    
}
