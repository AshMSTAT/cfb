#' @title Find and Parse Interceptions
#' 
#' 
#' @export


ParseInterception <- function(x){
  
  x$Interception = FALSE
  x$InterceptionYards = rep(NA, nrow(x))
  
  textMod <- as.character(x$scoreText)
  
  ragParsePass <- 
    paste0(
      '([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}) incomplete\\. '
      ,'(Intended for )([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}), '
      ,'(INTERCEPTED by .*)'
    )
  
  CondPass <- grepl(ragParsePass, x$scoreText)
  x$Passer[CondPass] = gsub(ragParsePass, '\\1', x[CondPass,'scoreText'])
  x$Receiver[CondPass] = gsub(ragParsePass, '\\3', x[CondPass,'scoreText'])
  x$Receiver[x$Receiver==''] = NA
  
  textMod[CondPass] = gsub(ragParsePass, '\\1 incomplete\\. \\4', x[CondPass,'scoreText'])
  
  # - Inteception
  regParse = 
    paste0(
      '([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}) incomplete. INTERCEPTED by '
      ,'([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}) at '
      ,'([A-Z]{2,4}) ([0-9]{1,3})\\. '
      ,'([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}) (to|runs|runs ob at) '
      ,'([A-Z]{2,4}) ([0-9]{1,3}) for ([0-9]{1,3}) '
      ,'(yard|yards)\\.'
    )
  Cond <- grepl(regParse, textMod) & !grepl('touchdown', textMod)
  
  x$Passer[Cond] = gsub(regParse, '\\1', textMod[Cond])
  x$Interceptor[Cond] = gsub(regParse, '\\2', textMod[Cond])
  x$Complete[Cond] = FALSE
  
  x$PassAtt[Cond] = TRUE
  x$Interception[Cond] = TRUE
  x$InterceptionYards[Cond] = gsub(regParse, '\\9', textMod[Cond])
  
  
  # - Pick 6
  regParse = 
    paste0(
      '([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}) incomplete. INTERCEPTED by '
      ,'([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}) at '
      ,'([A-Z]{2,4}) ([0-9]{1,3})\\. '
      ,'([0-9]{1,4}-[A-Z]\\.[A-Za-z\\-]{1,20}) runs '
      ,'([0-9]{1,3}) '
      ,'(yard|yards) for a touchdown\\.'
    )
  
  Cond2 <- grepl(regParse, textMod) & !Cond
  
  x$Passer[Cond2] = gsub(regParse, '\\1', textMod[Cond2])
  x$Interceptor[Cond2] = gsub(regParse, '\\2', textMod[Cond2])
  x$Complete[Cond2] = FALSE
  
  x$PassAtt[Cond2] = TRUE
  x$Interception[Cond2] = TRUE
  
  x$InterceptionYards[Cond2] = gsub(regParse, '\\6', textMod[Cond2])
  
  x$InterceptionYards = as.numeric(x$InterceptionYards)
  
  x
}