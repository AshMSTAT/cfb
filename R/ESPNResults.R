#' @title Scrape ESPN Game Results.
#' @description Using curl we pull all 254 teams schedules at once. Use this function sparingly as is hits ESPN's servers in an intense way. Takes about 25 seconds
#' 
#' @import XML curl dplyr
#' @importFrom tidyr separate
#' @importFrom jsonlite fromJSON
#' 
#' @export


ESPNResults <- function(Year = 2016, ESPNSource = NULL) {
  
  if(is.null(ESPNSource)){
    ESPNSource <- ESPNGET(Year)
  }
  
  IdJSON <- function(x){
    # Basically give me everything between { and } but keep the {}
    g1 <- gsub("(.*) \\{(.*)\\} (.*)","\\{\\2\\}", x)
    # add in leading double quotes so we can convert form JSON
    g2 <- gsub("(\\{| )([a-z]{1,})", '\\1"\\2', g1)
    # add in trailing double quotes so we can convert form JSON
    g3 <- gsub("([a-z]{1,})(\\:)", '\\1"\\2', g2)
    as.data.frame(fromJSON(g3))
  }
  
  CC <- lapply(ESPNSource, function(x){
    
    doc <- xml2::read_html(x$content)
    
    IdInfo <- rvest::html_nodes(doc, xpath="/html/body[contains(@class, 'ncf')]") %>% xml2::xml_attrs()
    Team <- rvest::html_nodes(doc, xpath='//*[@id="sub-branding"]/h2/a/b') %>% rvest::html_text()
    Info <- rvest::html_nodes(doc, xpath='//table//tr//td[contains(@colspan, 4)]') %>% rvest::html_text()
    
    data.frame(
      as.data.frame(rvest::html_table(doc))
      ,Team = Team[1]
      ,Info = Info[1]
      ,IdJSON(IdInfo[[1]][[1]])
    )
  })
  
  dirtyGames <- do.call(rbind, CC)
  
  cleanGames<-
  dirtyGames %>% 
    mutate(
      Home = as.numeric(substr(X2, 1, 2) == 'vs')
      # - Need to remove anything after a space just in case there is OT
      ,X3 = gsub(' [A-z0-9 ]*', '' , X3)
      ,Score = substr(X3, 2, 20)
      # - 1st char in either W or L for the games that have already been played
      ,Result = as.factor(substr(X3, 1, 1))
      # - Removing the vs or @
      ,Opponent = espnOpp(X2)
      ,Date = espnDate(paste(X1, Year))
      ,Year = substr(Info, 1, 4)
    ) %>%
    # - Keep games that haven't happened yet and have a Date
    filter(Result %in% c("W", "L")) %>%
    separate(Score, c("PF1", "PA1")) %>%
    select(
      Date
      ,Home
      ,PF1
      ,PA1
      ,Opponent
      ,Result
      ,Team
      ,Year
      ,espnID = teamId
      ,conferenceID = groupId
    )

  cleanGames <- Numerics(cleanGames)
  
  cleanGames$PF[cleanGames$Result=='L'] = cleanGames$PA1[cleanGames$Result=='L']
  cleanGames$PA[cleanGames$Result=='L'] = cleanGames$PF1[cleanGames$Result=='L']
  cleanGames$PF[cleanGames$Result=='W'] = cleanGames$PF1[cleanGames$Result=='W']
  cleanGames$PA[cleanGames$Result=='W'] = cleanGames$PA1[cleanGames$Result=='W']
  
  cleanGames <- select(cleanGames, -PF1, -PA1)
  
  return(cleanGames)
  
}

