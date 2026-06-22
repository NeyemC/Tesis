# =====================================================================
# 01_explore2.R — Pesos, N Chile, controles y escalas
# =====================================================================
suppressMessages({library(haven); library(dplyr)})
ip <- "input"
d99 <- read_sav(file.path(ip,"ZA3430_2006-09-14.sav"))
d09 <- read_sav(file.path(ip,"ZA5400_v4-0-0.sav"))
d19 <- read_sav(file.path(ip,"ZA7600_v3-0-0.sav"))

# --- Filtro Chile ---
c99 <- d99 %>% filter(zap_labels(V3)==30)
c09 <- d09 %>% filter(zap_labels(V5)==152)
c19 <- d19 %>% filter(as.character(c_alphan)=="CL")
cat("N Chile -> 1999:", nrow(c99), "| 2009:", nrow(c09), "| 2019:", nrow(c19), "\n\n")

# --- Pesos (case-insensitive) ---
cat("=== posibles pesos (case-insensitive) ===\n")
cat("1999:", grep("weight|wgt|factor|gewicht", names(d99), value=TRUE, ignore.case=TRUE), "\n")
cat("2009:", grep("weight|wgt|factor|gewicht", names(d09), value=TRUE, ignore.case=TRUE), "\n")
cat("2019:", grep("weight|wgt|factor|gewicht", names(d19), value=TRUE, ignore.case=TRUE), "\n\n")

descr <- function(d, v){
  if(!v %in% names(d)){cat(sprintf("  [%s] NO EXISTE\n",v));return(invisible())}
  lab <- attr(d[[v]],"label"); lab <- ifelse(is.null(lab),"",lab)
  x <- zap_labels(d[[v]])
  cat(sprintf("  [%s] %s | rango=[%s,%s] NA=%d\n", v, substr(lab,1,55),
      ifelse(all(is.na(x)),"-",min(x,na.rm=TRUE)), ifelse(all(is.na(x)),"-",max(x,na.rm=TRUE)), sum(is.na(x))))
}

cat("=== Controles candidatos 1999 ===\n")
cat("educ:", grep("educ|degree|school|isced", names(d99), value=TRUE, ignore.case=TRUE),"\n")
cat("income:", grep("inc|income|earn", names(d99), value=TRUE, ignore.case=TRUE),"\n")
cat("polit:", grep("party|left|right|polit|vote", names(d99), value=TRUE, ignore.case=TRUE),"\n")
cat("relig:", grep("relig|attend|church|god", names(d99), value=TRUE, ignore.case=TRUE),"\n\n")

cat("=== Controles candidatos 2009 ===\n")
cat("educ:", grep("educ|degree|school|isced", names(d09), value=TRUE, ignore.case=TRUE),"\n")
cat("income:", grep("inc|income|earn", names(d09), value=TRUE, ignore.case=TRUE),"\n")
cat("polit:", grep("party|left|right|polit|vote", names(d09), value=TRUE, ignore.case=TRUE),"\n")
cat("relig:", grep("relig|attend|church|god", names(d09), value=TRUE, ignore.case=TRUE),"\n\n")

cat("=== Controles candidatos 2019 ===\n")
cat("educ:", grep("educ|degree|school|isced", names(d19), value=TRUE, ignore.case=TRUE),"\n")
cat("income:", grep("inc|income|earn", names(d19), value=TRUE, ignore.case=TRUE),"\n")
cat("polit:", grep("party|left|right|polit|vote", names(d19), value=TRUE, ignore.case=TRUE),"\n")
cat("relig:", grep("relig|attend|church|god", names(d19), value=TRUE, ignore.case=TRUE),"\n\n")

cat("=== Escala VD salud por ola (zap_labels, tabla cruda) ===\n")
cat("1999 V39:\n"); print(table(zap_labels(c99$V39), useNA="ifany"))
cat("2009 V38:\n"); print(table(zap_labels(c09$V38), useNA="ifany"))
cat("2019 v30:\n"); print(table(zap_labels(c19$v30), useNA="ifany"))

cat("\n=== Escala getting-ahead ej. (educación propia) ===\n")
cat("2009 V8:\n"); print(table(zap_labels(c09$V8), useNA="ifany"))
cat("2019 v3:\n"); print(table(zap_labels(c19$v3), useNA="ifany"))

cat("\n=== AGE en Chile por ola ===\n")
for(z in list(c99,c09,c19)) {a<-zap_labels(z$AGE); cat(" rango AGE:", min(a,na.rm=TRUE),"-",max(a,na.rm=TRUE)," NA=",sum(is.na(a)),"\n")}
