#!/usr/bin/env ruby

# this is a quick and dirty solution to try to at least get some country codes done
# we're just normalizing by removing punctuation, spaces, and downcasing everything...

# todo: refactor normalize_text out...

def normalize( text )
  text.gsub(/\s/,'').gsub(/[[:punct:]]/, '').gsub(/\p{S}/,'').downcase
end


mapping = File.open('country_lookup.map','w')

File.open('alma_country_codes.tsv','r').readlines.each do | line |

  line = line.chomp

  (code, text) = line.split("\t")

  mapping.puts( normalize( text ) + ',' + code )
  
  
end



# these are some guesses....otherwise should dig around and see if there are two character and three character code standards for countries and shipping

# US = USA
# CH = CHINA
# IN = INDIA

mapping.puts( normalize( 'CN' ) + ',' + 'CHN' )
mapping.puts( normalize( 'US' ) + ',' + 'USA' ) 
mapping.puts( normalize( 'IN' ) + ',' + 'IND' )



# at some point I need to clean these up...but they come from somewhere...
#AC
#AE
#AF
#AG
#AJ
#AL
#AM
#AO
#AQ
#AR
#AS
#AU
#AV
#AX
#AY
#BA
#BB
#BC
#BD
#BE
#BEL
#BF
#BG
#BH
#BK
#BL
#BM
#BN
#BO
#BR
#BRA
#BU
#BWA
#BX
#BY
#CA
#CAN
#CB
#CD
#CE
#CF
#CG
#CH
#CHN
#CI
#CJ
#CK
#CM
#CN
#CO
#CQ
#CS
#CY
#DA
#DEU
#DM
#DO
#DR
#EC
#ED
#EG
#EI
#EN
#ER
#ES
#ET
#EZ
#FI
#FJ
#FM
#FR
#FRA
#GA
#GB
#GBR
#GG
#GH
#GI
#GJ
#GM
#GQ
#GR
#GT
#GTM
#GU
#GV
#GY
#GZ
#HA
#HK
#HO
#HR
#HU
#IC
#ID
#IDN
#IM
#IN
#IND
#IR
#IS
#IT
#IV
#IZ
#JA
#JM
#JO
#JPN
#KE
#KEN
#KG
#KN
#KOR
#KR
#KS
#KT
#KU
#KZ
#LA
#LE
#LG
#LH
#LI
#LO
#LT
#LTU
#LU
#LY
#MA
#MC
#MD
#MG
#MI
#MJ
#MK
#ML
#MN
#MO
#MP
#MR
#MS
#MT
#MU
#MV
#MX
#MY
#MZ
#NC
#NE
#NG
#NI
#NL
#NN
#NO
#NP
#NS
#NU
#NZ
#OT
#PA
#PAK
#PE
#PHL
#PK
#PL
#PM
#PO
#PP
#PU
#QA
#RI
#RM
#RO
#RP
#RQ
#RS
#RW
#SA
#SC
#SD
#SE
#SF
#SG
#SI
#SL
#SN
#SO
#SP
#ST
#SU
#SW
#SY
#SZ
#TC
#TD
#TH
#TI
#TK
#TO
#TS
#TT
#TU
#TW
#TWN
#TX
#TZ
#UC
#UG
#UK
#UP
#US
#UV
#UY
#UZ
#VC
#VE
#VI
#VM
#VQ
#WA
#WB
#WZ
#YM
#ZA
#ZI

