/** @class Use a style sheet to transform XML. Requires Rhino. */
function Transformer(xsl) { //like: var t = new Transformer("data/teststyle.xsl");
	var xsltFile = new Packages.java.io.File(xsl);
	var xsltSource = new Packages.javax.xml.transform.stream.StreamSource(xsltFile);
	this.transformer = Packages.javax.xml.transform.TransformerFactory.newInstance().newTransformer(xsltSource);
}

Transformer.prototype.transform = function(xml, out) { //like: t.transform("data/testdata.xml", "data/testout.txt");
	var xmlFile = new Packages.java.io.File(xml);
	var resFile = new Packages.java.io.File(out);
	var xmlSource = new Packages.javax.xml.transform.stream.StreamSource(xmlFile);
	var result = new Packages.javax.xml.transform.stream.StreamResult(resFile);
	this.transformer.transform(xmlSource, result);
}