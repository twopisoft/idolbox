//
//  Constants.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation

struct Constants {
    static let kApiKey              = "IDOL_APIKey"
    static let kMaxResults          = "IDOL_MaxResults"
    static let kSummaryStyle        = "IDOL_SummaryStyle"
    static let kSortStyle           = "IDOL_SortStyle"
    static let kSettingsPasscode    = "IDOL_SettingsPasscode"
    static let kSearchIndexes       = "IDOL_SearchIndexes"
    static let kAddIndex            = "IDOL_AddIndex"
    
    static let ApiKeyParam          = "apikey"
    static let IndexesParam         = "indexes"
    static let RelevanceParam       = "relevance"
    static let SortParam            = "sort"
    static let SummaryParam         = "summary"
    static let MaxResultParam       = "absolute_max_results"
    static let HighlightParam       = "highlight"
    static let PrintFieldParam      = "print_fields"
    static let StartTagParam        = "start_tag"
    
    static let SummaryStyleQuick    = "quick"
    static let SummaryStyleContext  = "context"
    static let SummaryStyleConcept  = "concept"
    
    static let StartTagStyle        = "<span style='background-color:yellow; color:black'>"
    
    static let SortStyleRelevance   = "relevance"
    static let SortStyleDate        = "date"
    
    static let HighlightStyleSentence           = "sentences"
    static let HighlightStyleSummarySentence    = "summary_sentences"
    static let HighlightStyleSummaryTerms       = "summary_terms"
    
    static let PrintFieldDate       = "modified_date"
    
    static let SelectIndexSearchSegue   = "SelectIndexSearch"
    static let SelectIndexAddSegue      = "SelectIndexAdd"
    
    static let FindSelectIndexSegue     = "FindSelectIndex"
    
    static let SearchResultSegue        = "SearchResult"
    
    static let SearchResultDetailSegue  = "SearchResultDetail"
    
    static let DefaultSearchIndex       = "wiki_eng"
}
