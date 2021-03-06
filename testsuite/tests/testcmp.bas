' Test comparisons:
a=1234
? "INTEGER TESTS"
? "Pos <=> Pos EQ"
?  1234 < a,  1234 <= a,  1234 > a,  1234 >= a,  1234 <> a,  1234 = a
?  1235 < a,  1235 <= a,  1235 > a,  1235 >= a,  1235 <> a,  1235 = a
?  1233 < a,  1233 <= a,  1233 > a,  1233 >= a,  1233 <> a,  1233 = a
? "Pos <=> Pos -256"
?   977 < a,   977 <= a,   977 > a,   977 >= a,   977 <> a,   977 = a
?   978 < a,   978 <= a,   978 > a,   978 >= a,   978 <> a,   978 = a
?   979 < a,   979 <= a,   979 > a,   979 >= a,   979 <> a,   979 = a
? "Pos <=> Neg EQ"
? -1234 < a, -1234 <= a, -1234 > a, -1234 >= a, -1234 <> a, -1234 = a
? -1235 < a, -1235 <= a, -1235 > a, -1235 >= a, -1235 <> a, -1235 = a
? -1233 < a, -1233 <= a, -1233 > a, -1233 >= a, -1233 <> a, -1233 = a
? "Pos <=> Neg -256"
? -1490 < a, -1490 <= a, -1490 > a, -1490 >= a, -1490 <> a, -1490 = a
? -1491 < a, -1491 <= a, -1491 > a, -1491 >= a, -1491 <> a, -1491 = a
? -1489 < a, -1489 <= a, -1489 > a, -1489 >= a, -1489 <> a, -1489 = a
a=-1234
? "Neg <=> Pos -256"
?   977 < a,   977 <= a,   977 > a,   977 >= a,   977 <> a,   977 = a
?   978 < a,   978 <= a,   978 > a,   978 >= a,   978 <> a,   978 = a
?   979 < a,   979 <= a,   979 > a,   979 >= a,   979 <> a,   979 = a
? "Neg <=> Pos EQ"
?  1234 < a,  1234 <= a,  1234 > a,  1234 >= a,  1234 <> a,  1234 = a
?  1235 < a,  1235 <= a,  1235 > a,  1235 >= a,  1235 <> a,  1235 = a
?  1233 < a,  1233 <= a,  1233 > a,  1233 >= a,  1233 <> a,  1233 = a
? "Neg <=> Neg EQ"
? -1234 < a, -1234 <= a, -1234 > a, -1234 >= a, -1234 <> a, -1234 = a
? -1235 < a, -1235 <= a, -1235 > a, -1235 >= a, -1235 <> a, -1235 = a
? -1233 < a, -1233 <= a, -1233 > a, -1233 >= a, -1233 <> a, -1233 = a
? "Neg <=> Neg -256"
? -1490 < a, -1490 <= a, -1490 > a, -1490 >= a, -1490 <> a, -1490 = a
? -1491 < a, -1491 <= a, -1491 > a, -1491 >= a, -1491 <> a, -1491 = a
? -1489 < a, -1489 <= a, -1489 > a, -1489 >= a, -1489 <> a, -1489 = a
a=0
? "0 <=> 0"
?   0 < a,   0 <= a,   0 > a,   0 >= a,   0 <> a,   0 = a
?   1 < a,   1 <= a,   1 > a,   1 >= a,   1 <> a,   1 = a
?  -1 < a,  -1 <= a,  -1 > a,  -1 >= a,  -1 <> a,  -1 = a
? 256 < a, 256 <= a, 256 > a, 256 >= a, 256 <> a, 256 = a

x% = 12.34
? "FP TESTS"
? "1 < : "; : if 12.34 <  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 < : "; : if  0.98 <  x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 < : "; : if  1134 <  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 > : "; : if 12.34 >  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 > : "; : if  0.98 >  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 > : "; : if  1134 >  x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 <=: "; : if 12.34 <= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 <=: "; : if  0.98 <= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <=: "; : if  1134 <= x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 >=: "; : if 12.34 >= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 >=: "; : if  0.98 >= x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 >=: "; : if  1134 >= x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 = : "; : if 12.34 =  x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 = : "; : if  0.98 =  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 = : "; : if  1134 =  x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 <>: "; : if 12.34 <> x% : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 <>: "; : if  0.98 <> x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <>: "; : if  1134 <> x% : ? "PASS" : ELSE : ? "FAIL" : ENDIF

' Force a null string, defined but not set:
if 0 then nul$="NONE"

s$ = "Hello"
? "STR TESTS"
? "1 < : "; : if "Hello" <  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 < : "; : if "Hell"  <  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 < : "; : if "Hold"  <  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "4 < : "; : if "Hellos" < s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "5 < : "; : if "Hall"  <  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "6 < : "; : if nul$    <  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "7 < : "; : if s$    <  nul$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 > : "; : if "Hello" >  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 > : "; : if "Hell"  >  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 > : "; : if "Hold"  >  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "4 > : "; : if "Hellos" > s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "5 > : "; : if "Hall"  >  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 <=: "; : if "Hello" <= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 <=: "; : if "Hell"  <= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <=: "; : if "Hold"  <= s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 >=: "; : if "Hello" >= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 >=: "; : if "Hell"  >= s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 >=: "; : if "Hold"  >= s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "1 = : "; : if "Hello" =  s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "2 = : "; : if "Hell"  =  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "3 = : "; : if "Hold"  =  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "4 = : "; : if nul$    =  s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "5 = : "; : if s$    =  nul$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "1 <>: "; : if "Hello" <> s$ : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "2 <>: "; : if "Hell"  <> s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "3 <>: "; : if "Hold"  <> s$ : ? "PASS" : ELSE : ? "FAIL" : ENDIF

? "BOOL EXPR TESTS"
x0 = 0 : x1 = 1 : x256 = 256 : a = 1234
? "AND/OR:  "; : if x0 and x1 or x1: ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "OR/AND:  "; : if x1 or x1 and x0: ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "NOT/AND: "; : if NOT x0 AND x0  : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "NOT/AND: "; : if NOT (x0 and x0): ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "NOT/NOT: "; : if NOT ((NOT x0)) : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "NOT/NOT: "; : if NOT NOT x0     : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "NOT/NOT: "; : if x1 = NOT NOT a : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "NOT/+:   "; : if NOT x0 + x1    : ? "FAIL" : ELSE : ? "PASS" : ENDIF
? "(NOT)/+: "; : if (NOT x0) + x1  : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "conv:    "; : if x256           : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "par:     "; : if (x0<x1)        : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "> <>:    "; : if x1>x0<>x0      : ? "PASS" : ELSE : ? "FAIL" : ENDIF
? "> <>:    "; : if (x1>x0<>x0)    : ? "PASS" : ELSE : ? "FAIL" : ENDIF

