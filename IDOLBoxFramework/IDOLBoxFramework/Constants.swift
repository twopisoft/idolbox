//
//  Constants.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation

public struct Constants {
    public static let GroupContainerName   = "group.com.twopi.IDOLBox"
    
    public static let IDOLService          = "IDOLService"
    
    public static let kApiKey              = "IDOL_APIKey"
    public static let kMaxResults          = "IDOL_MaxResults"
    public static let kSummaryStyle        = "IDOL_SummaryStyle"
    public static let kSortStyle           = "IDOL_SortStyle"
    public static let kSettingsPasscode    = "IDOL_SettingsPasscode"
    public static let kSearchIndexes       = "IDOL_SearchIndexes"
    public static let kAddIndex            = "IDOL_AddIndex"
    
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
    
    public static let ModDateJson          = "{\"modified_date\":[\"%@\"]}"
    
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
    
}
