grammar silver:modification:impide:cstast;

imports silver:definition:concrete_syntax:ast;
imports silver:definition:regex;
imports silver:definition:type;
imports silver:definition:env;

imports silver:translation:java:core only makeIdName, makeClassName, makeNTClassName;
imports silver:translation:java:type only transType;
imports silver:modification:impide;

-- The attribute into which the copper parser in new XML skin is written
synthesized attribute nxmlCopper :: String occurs on SyntaxRoot, Syntax, SyntaxDcl;

-- The attribute carries the name of IDE plugin packge, which is ultimately 
-- derived from the name of grammar where IDE declaration block is defined.
inherited attribute jPkgName :: String occurs on SyntaxRoot;
-- The attribute is the name of generated Java parser.
inherited attribute jParserName :: String occurs on SyntaxRoot;

aspect default production
top::SyntaxRoot ::=
{
  top.nxmlCopper = error("This should only ever be demanded from cstRoot.");
  top.fontList = error("This should only ever be demanded from cstRoot.");
  top.termFontPairList = error("This should only ever be demanded from cstRoot.");
}

aspect production cstRoot
top::SyntaxRoot ::= parsername::String  startnt::String  s::Syntax
{

  -- 1) font information
  top.fontList = s2.fontList;
  top.termFontPairList = s2.termFontPairList;

  -- 2) The copper parser
  top.nxmlCopper =
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n" ++

"<CopperSpec xmlns=\"http://melt.cs.umn.edu/copper/xmlns\">\n" ++
"  <Parser id=\"" ++ makeCopperName(parsername) ++ "\" isUnitary=\"true\">\n" ++
"    <PP>" ++ parsername ++ "</PP>\n" ++
"    <Grammars><GrammarRef id=\"" ++ s2.containingGrammar ++ "\"/></Grammars>\n" ++
"    <StartSymbol>" ++ xmlCopperRef(head(startFound)) ++ "</StartSymbol>\n" ++
"    <StartLayout>" ++ univLayout ++ "</StartLayout>\n" ++
-- DIFFERENCES ****************************************************************
"    <ClassAuxiliaryCode>\n" ++
"      <Code><![CDATA[\n" ++ 
  getAuxCode(top.jPkgName ++ ".imp.coloring." ++ top.jParserName ++ "_") ++
"      ]]></Code>\n" ++
"    </ClassAuxiliaryCode>\n" ++
"    <ParserInitCode>\n" ++
"      <Code><![CDATA[\n" ++
"        reset();\n" ++
"      ]]></Code>\n" ++
"    </ParserInitCode>\n" ++
"    <Preamble>\n" ++
"<Code><![CDATA[\n" ++
"import java.util.ArrayList;\n" ++
"import java.util.Iterator;\n" ++
"import java.util.List;\n" ++
"import edu.umn.cs.melt.copper.runtime.engines.single.scanner.SingleDFAMatchData;\n" ++
"import edu.umn.cs.melt.ide.copper.*;\n" ++
"import edu.umn.cs.melt.ide.copper.coloring.*;\n" ++
"]]></Code>\n" ++
"    </Preamble>\n" ++
"    <SemanticActionAuxiliaryCode>\n" ++
"      <Code><![CDATA[\n" ++ 
"private int getCurrentProduction(){\n" ++
"  return _prod;\n" ++
"}\n" ++
"      ]]></Code>\n" ++
"    </SemanticActionAuxiliaryCode>\n" ++
-- END DIFFERENCES ************************************************************
"  </Parser>\n\n" ++

"  <Grammar id=\"" ++ s2.containingGrammar ++ "\">\n\n" ++
"    <PP>" ++ s2.containingGrammar ++ "</PP>\n\n" ++
"    <Layout>" ++ univLayout ++ "</Layout>\n\n" ++
"    <Declarations>\n" ++
"      <ParserAttribute id=\"context\">\n" ++
"        <Type><![CDATA[common.DecoratedNode]]></Type>\n" ++
"        <Code><![CDATA[context = common.TopNode.singleton;]]></Code>\n" ++
"      </ParserAttribute>\n" ++
       s2.nxmlCopper ++
"    </Declarations>\n" ++
"  </Grammar>\n" ++
"</CopperSpec>\n";
}


{-
Assumptions we make about initial Syntax:

1. All type parameter lists are the appropriate length. (Silver type checking)
-}

function getAuxCode
String ::= classPrefix::String
{
return 
"\t//IDE Extension START\n" ++
"    \n" ++
"\tprotected AdaptiveEnhancedParseTreeInnerNode createPTNode(final Object obj){\n" ++
"\t    int production = semantics.getCurrentProduction();\n" ++
"\t\tnodeBuilder.setLangSpecNode(obj);\n" ++
"\t\tint _productionLength = actionIndex(getSymbolNumbers()[production]);\n" ++
"\t\tint _productionLHS = actionIndex(getProductionLHSs()[production - getGRAMMAR_SYMBOL_COUNT()]);\n" ++
"\t\tenParseTree.reduce(nodeBuilder, production, _productionLength, _productionLHS);\n" ++
"\t\treturn (AdaptiveEnhancedParseTreeInnerNode)enParseTree.getLowestNode();\n" ++
"\t}\n" ++
"\t\n" ++
"\tprotected void shiftPTNode(final Object obj, SingleDFAMatchData scanResult){\n" ++
"\t\tnodeBuilder.setLangSpecNode(obj);\n" ++
"\t\tenParseTree.shift(nodeBuilder, scanResult, _startOffset, _endOffset);\n" ++
"\t}\n" ++
"\t\n" ++
"\tprotected void shiftPTNode(SingleDFAMatchData scanResult){\n" ++
"\t\tshiftPTNode(null, scanResult);\n" ++
"\t}\n" ++
"\t\n" ++
"\tclass AdaptiveParseNodeBuilder implements ParseNodeBuilder<IEnhancedParseTreeNode> {\n" ++
"\t\tprivate Object langSpecNode;\n" ++
"\t\t\n" ++
"\t\tAdaptiveParseNodeBuilder(){\n" ++
"\n" ++
"\t\t}\n" ++
"\t\t\n" ++
"\t\tvoid setLangSpecNode(Object langSpecNode){\n" ++
"\t\t\tthis.langSpecNode = langSpecNode;\n" ++
"\t\t}\n" ++
"\t\t\n" ++
"\t\t@Override\n" ++
"\t\tpublic AdaptiveEnhancedParseTreeInnerNode<Object> buildNode(\n" ++
"\t\t\tIEnhancedParseTreeNode[] children, int production, int term) {\n" ++
"\t\t\t\n" ++
"\t\t\tint start = 0;\n" ++
"\t\t\tint end = 0;\n" ++
"\t\t\t\n" ++
"\t\t\tif(children != null && children.length>0){\n" ++
"\t\t\t\tstart = children[0].getStart();\n" ++
"\t\t\t\tend = children[children.length-1].getEnd();\n" ++
"\t\t\t} else if (tokenList != null) {\n" ++
"\t\t\t\t//For empty production (RHS = 0), use the last token scanned as the location\n" ++
"\t\t\t\tint sz = tokenList.size();\n" ++
"\t\t\t\tif(sz>0){\n" ++
"\t\t\t\t\tstart = tokenList.get(sz-1).getEndOffset() + 1;\n" ++
"\t\t\t\t\tend = start;\n" ++
"\t\t\t\t}\n" ++
"\t\t\t}\n" ++
"\t\t\t\n" ++
"\t\t\treturn new AdaptiveEnhancedParseTreeInnerNode<Object>(\n" ++
"\t\t\t\t\tchildren, production, term, start, end, langSpecNode);\n" ++
"\t\t}\n" ++
"\n" ++
"\t\t@Override\n" ++
"\t\tpublic AdaptiveEnhancedParseTreeLeafNode<Object> buildNode(\n" ++
"\t\t\tSingleDFAMatchData scanResult, int start, int end) {\n" ++
"\t\t\treturn new AdaptiveEnhancedParseTreeLeafNode<Object>(\n" ++
"\t\t\t\tscanResult.lexeme, scanResult.firstTerm, start, end, langSpecNode);\n" ++
"\t\t}\n" ++
"\t}\n" ++
"\t\n" ++

"\tprivate AdaptiveParseNodeBuilder nodeBuilder = new AdaptiveParseNodeBuilder();\n" ++
"\t\n" ++
"\t//The following variables are used for building token list\n" ++
"\tprivate int _totalOffset = 0;\n" ++
"\tprivate int _startOffset = 0;\n" ++
"\tprivate int _endOffset = 0;\n" ++
"\tprotected List<IToken> tokenList = null;\n" ++
"\tprivate final Object LOCK = new Object();\n" ++
"\n" ++
"    private void addToken(SingleDFAMatchData _terminal){\n" ++
"    	IToken t = createToken(_terminal);\n" ++
"\t\tif(t != null){\n" ++
"\t\t\tsynchronized(LOCK){\n" ++
"\t\t\t\ttokenList.add(t);\n" ++
"\t\t\t}\n" ++
"\t\t}  	\n" ++
"    }\n" ++
"    \n" ++

"    /**\n" ++
"     * Called at start of parsing\n" ++
"     */\n" ++
"\tpublic void reset(){\n" ++
"\t\tsynchronized(LOCK){\n" ++
"\t\t\ttokenList = new ArrayList<IToken>();\n" ++
"\t\t}\n" ++
"\t\t_totalOffset = 0;\n" ++
"\t\t_startOffset = 0;\n" ++
"\t\t_endOffset = 0;\n" ++
"\t\tstartColumnForNextToken = 1;\n" ++
"\t\tenParseTree.clear();\n" ++
"\t}\n" ++
"\t\n" ++

"\tprivate int startColumnForNextToken = 1;\n" ++ 
"\t\n" ++
"\tprivate final static String SEPARATOR = System.getProperty(\"line.separator\").toString();\n" ++
"\t\n" ++

"    protected IToken createToken(SingleDFAMatchData scanResult) {\n" ++
"    	_startOffset = _totalOffset;\n" ++
"\t\tif(scanResult.lexeme.length()>0){\n" ++
"\t\t\t_totalOffset += scanResult.lexeme.length();\n" ++
"\t\t}\n" ++
"\t\t_endOffset = _totalOffset;\n" ++
"    	if(_startOffset == _endOffset){\n" ++
"    		return null;\n" ++
"    	}\n" ++
"    	\n" ++
"    	_endOffset--;\n" ++
"\t\tint line =  virtualLocation.getLine();\n" ++
"\t\tint endColumn = virtualLocation.getColumn();\n" ++
"\t\tint startColumn = scanResult.lexeme.startsWith(SEPARATOR) ? 0 : startColumnForNextToken;\n" ++
"\t\tstartColumnForNextToken = endColumn + 1;\n" ++
"\t\tint kind = getKind(scanResult);\n" ++
"\t\t\n" ++
"\t\treturn new EnhancedCopperToken(\n" ++
"\t\t\tkind, \n" ++
"\t\t\tscanResult.firstTerm, \n" ++
"\t\t\ttokenList.size(), \n" ++
"\t\t\t_startOffset, \n" ++
"\t\t\t_endOffset, \n" ++
"\t\t\tline, \n" ++
"\t\t\tline, \n" ++
"\t\t\tstartColumn, \n" ++
"\t\t\tendColumn);\n" ++
"\t}\n" ++
"    \n" ++

"    class EnhancedCopperToken extends CopperToken {\n" ++
"\t\tprivate String str;\n" ++
"\t\t\n" ++
"\t\tpublic EnhancedCopperToken(int kind, int term, int tokenIndex, int startOffset,\n" ++
"\t\t\t\tint endOffset, int startLine, int endLine, int startColumn, \n" ++
"\t\t\t\tint endColumn) {\n" ++
"\t\t\tsuper(kind, term, tokenIndex, startOffset, endOffset, startLine, endLine, \n" ++
"\t\t\t\tstartColumn, endColumn);\n" ++
"\t\t}\n" ++
"\t\t\n" ++
"\t\tpublic String toString(){\n" ++
"\t\t\tif(str==null){\n" ++
"\t\t\t\tstr = \"[\" + getSymbolNames()[term] + \":\" + startLine + \"/\" + startColumn + \"(\" + startOffset + \"/\" + endOffset + \")]\";\n" ++
"\t\t\t}\n" ++
"\t\t\t\n" ++
"\t\t\treturn str;\n" ++
"\t\t}\n" ++
"    }\n" ++
"\t\n" ++

"\tpublic void printTokenList(){\n" ++
"\t\tIterator<IToken> iter = tokenList.iterator();\n" ++
"\t\tStringBuilder sb = new StringBuilder(\"TOKEN LIST (\" + tokenList.size() + \" in total) = \");\n" ++
"\t\twhile(iter.hasNext()){\n" ++
"\t\t\tsb.append(iter.next().toString());\n" ++
"\t\t\tsb.append(\", \");\n" ++
"\t\t}\n" ++
"\t\tSystem.out.println(sb);\n" ++
"\t}\n" ++
"\t\n" ++

"\tpublic Iterator<IToken> getTokenIterator(org.eclipse.jface.text.IRegion region) {\n" ++
"\t\tint startOffset = region.getOffset();\n" ++
"\t\tint endOffset = startOffset + region.getLength();\n" ++
"\t\t\n" ++
"\t\tList<IToken> list = new ArrayList<IToken>();\n" ++
"\t\tsynchronized(LOCK){\n" ++
"\t\t\tIterator<IToken> iter = tokenList.iterator();\n" ++
"\t\t\twhile(iter.hasNext()){\n" ++
"\t\t\t\tIToken next = iter.next();\n" ++
"\t\t\t\tif(next.getStartOffset() < startOffset || next.getEndOffset() > endOffset){\n" ++
"\t\t\t\t\tcontinue;\n" ++
"\t\t\t\t} else {\n" ++
"\t\t\t\t\tlist.add(next);\n" ++
"\t\t\t\t}\n" ++
"\t\t\t}\n" ++
"\t\t}\n" ++
"\t\t\n" ++
"\t\treturn list.iterator();\n" ++
"\t}\n" ++
"\t    \n" ++

"    /**\n" ++
"     * The parse tree generated during the parsing process.\n" ++
"     */\n" ++
"    protected EnhancedParseTree<IEnhancedParseTreeNode> enParseTree = new EnhancedParseTree<IEnhancedParseTreeNode>();\n\n" ++

"\tprotected int getKind(SingleDFAMatchData scanResult){\n" ++
"\t\tString term = getSymbolNames()[scanResult.firstTerm];\n" ++
"\t\treturn tokenClassifier.getKind(term);\n" ++
"\t}\n\n" ++
"\t\n" ++
"\tprivate ICopperTokenClassifier tokenClassifier = " ++ classPrefix ++ "TokenClassifier.getInstance();\n" ++
"\t//IDE Extension END\n";
}