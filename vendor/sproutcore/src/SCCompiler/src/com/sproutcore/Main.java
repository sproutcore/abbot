package com.sproutcore;

import static org.kohsuke.args4j.ExampleMode.ALL;
import org.kohsuke.args4j.Argument;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;

import java.util.ArrayList;
import java.util.List;
import java.io.File;
import java.io.IOException;
import java.io.FileReader;
import java.io.FileWriter;

//import com.google.common.collect.ImmutableList;
//import com.google.javascript.jscomp.CheckLevel;
//import com.google.javascript.jscomp.ClosureCodingConvention;
//import com.google.javascript.jscomp.CompilationLevel;
//import com.google.javascript.jscomp.Compiler;
//import com.google.javascript.jscomp.CompilerOptions;
//import com.google.javascript.jscomp.JSSourceFile;
//import com.google.javascript.jscomp.Result;
//import com.google.javascript.jscomp.CommandLineRunner;
//import com.google.javascript.jscomp.DiagnosticGroups;
//
import com.googlecode.htmlcompressor.DefaultErrorReporter;
import com.googlecode.htmlcompressor.compressor.HtmlCompressor;

import org.mozilla.javascript.ErrorReporter;
import org.mozilla.javascript.EvaluatorException;
import com.yahoo.platform.yui.compressor.CssCompressor;
import com.yahoo.platform.yui.compressor.JavaScriptCompressor;
import java.io.BufferedReader;
import java.util.logging.Level;

public class Main {

    @Option(name = "-adv", usage = "advanced mode")
    private boolean advanced;
    @Option(name = "-yuionly", usage = "Yui compressor only")
    private boolean yuionly;
    @Argument
    private List<String> arguments = new ArrayList<String>();

    public static void main(String[] args) throws IOException {
        new Main().doMain(args);
    }

    /**
     * Compiles the code using the specified configuration.
     * @param file JavaScript source code to compile.
     * @param level The compilation level to use when compiling the code.
     * @param boolean prettyPrint True to pretty-print the compiled code.
     * @param externs to use when compiling the code.
     * @return The compiled version of the code.
     * @throws CmdLineException if compilation is unsuccessful.
     */
//    public static String compile(File file, CompilationLevel level,
//            boolean prettyPrint, List<JSSourceFile> externs) throws Exception {
//        // A new Compiler object should be created for each compilation because
//        // using a previous Compiler will retain state from a previous compilation.
//        Compiler compiler = new Compiler();
//        CompilerOptions options = new CompilerOptions();
//        // setOptionsForCompilationLevel() configures the appropriate options on the
//        // CompilerOptions object.
//
//        level.setOptionsForCompilationLevel(options);
//        // Options can also be configured by modifying the Options object directly.
//        options.prettyPrint = prettyPrint;
//
//
//        // This is an important setting that the Closure Compiler Application uses
//        // to ensure that its type checking logic uses the type annotations used by
//        // Closure.
//        options.setWarningLevel(DiagnosticGroups.ACCESS_CONTROLS, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.AMBIGUOUS_FUNCTION_DECL, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.CHECK_REGEXP, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.CHECK_TYPES, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.CHECK_VARIABLES, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.DEPRECATED, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.EXTERNS_VALIDATION, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.FILEOVERVIEW_JSDOC, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.INVALID_CASTS, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.MISSING_PROPERTIES, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.NON_STANDARD_JSDOC, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.STRICT_MODULE_DEP_CHECK, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.UNDEFINED_VARIABLES, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.UNKNOWN_DEFINES, CheckLevel.OFF);
//        options.setWarningLevel(DiagnosticGroups.VISIBILITY, CheckLevel.OFF);
//
//        options.setCodingConvention(new ClosureCodingConvention());
//
//        // Input to the compiler must be associated with a JSSourceFile object.
//        // The dummy input name "input.js" is used here so that any warnings or
//        // errors will cite line numbers in terms of input.js.
//        JSSourceFile input = JSSourceFile.fromFile(file);
//        List<JSSourceFile> inputs = ImmutableList.of(input);
//        // compile() returns a Result that contains the warnings and errors.
//        compiler.setLoggingLevel(Level.WARNING);
//        Result result = compiler.compile(externs, inputs, options);
//        if (result.success) {
//            // The Compiler is responsible for generating the compiled code; the
//            // compiled code is not accessible via the Result.
//            return compiler.toSource();
//        } else {
//            // If compilation was unsuccessful, throw an exception. It is up to the
//            // client to read the errors and warnings out of the exception to display
//            // them.
//            System.err.println(result.debugLog);
//            throw new Exception("Closure couldn't minify. Check errors");
//        }
//    }

    public void doMain(String[] args) throws IOException {
        CmdLineParser parser = new CmdLineParser(this);
        ArrayList v = new ArrayList();
        ArrayList types = new ArrayList();
        ArrayList<File> fileArray = new ArrayList<File>();
        int i = 0, size = 0;
        String type = null, inputFilename, compiledCode;
        File f;
        FileReader in = null;
        FileWriter out = null;
//        List<JSSourceFile> externs = CommandLineRunner.getDefaultExterns();

        System.out.println("Starting minification...");
        try {
            // parse the arguments.
            parser.parseArgument(args);

            // you can parse additional arguments if you want.
            // parser.parseArgument("more","args");

            // after parsing arguments, you should check
            // if enough arguments are given.

            if (arguments.isEmpty()) {
                throw new CmdLineException("No argument is given");
            } else {
                if (advanced) {
                    System.out.println("-adv flag is set");
                }

                if (yuionly) {
                    System.out.println("-yuionly flag is set");
                }


                // access non-option arguments

                for (i = 0; i < arguments.size(); i++) {
                    inputFilename = arguments.get(i);
                    f = new File(inputFilename);

                    visitAllDirsAndFiles(f, fileArray);
                }
            }

            for (i = 0; i < fileArray.size(); i++) {
                f = (File) fileArray.get(i);
                System.out.println(f.getAbsolutePath());
//                if (f.getName().toLowerCase().endsWith(".js") && !yuionly) {
//                    compiledCode = compile(
//                            f,
//                            advanced ? CompilationLevel.ADVANCED_OPTIMIZATIONS
//                            : CompilationLevel.SIMPLE_OPTIMIZATIONS,
//                            false,// do not prettyPrint the output
//                            externs);
//                    System.out.println("_____________________________________________");
//                    System.out.println("--- Minifying JS using Closure... " + f.getAbsolutePath());
//                    out = new FileWriter(f);
//                    out.write(compiledCode);
//                    out.close();
//                } else
                if (f.getName().toLowerCase().endsWith(".js")/* && yuionly*/) {
                    System.out.println("_____________________________________________");
                    System.out.println("--- Minifying JS using YUICompressor... " + f.getAbsolutePath());
                    try {

                        in = new FileReader(f);

                        JavaScriptCompressor compressor = new JavaScriptCompressor(in, new ErrorReporter() {

                            public void warning(String message, String sourceName,
                                    int line, String lineSource, int lineOffset) {
                                if (line < 0) {
                                    System.err.println("\n[WARNING] " + message);
                                } else {
                                    System.err.println("\n[WARNING] " + line + ':' + lineOffset + ':' + message);
                                }
                            }

                            public void error(String message, String sourceName,
                                    int line, String lineSource, int lineOffset) {
                                if (line < 0) {
                                    System.err.println("\n[ERROR] " + message);
                                } else {
                                    System.err.println("\n[ERROR] " + line + ':' + lineOffset + ':' + message);
                                }
                            }

                            public EvaluatorException runtimeError(String message, String sourceName,
                                    int line, String lineSource, int lineOffset) {
                                error(message, sourceName, line, lineSource, lineOffset);
                                return new EvaluatorException(message);
                            }
                        });

                        // Close the input stream first, and then open the output stream,
                        // in case the output file should override the input file.
                        in.close();
                        in = null;

                        out = new FileWriter(f);

                        boolean munge = false;
                        boolean preserveAllSemiColons = false;
                        boolean disableOptimizations = false;
                        int linebreakpos = 80;
                        boolean verbose = false;

                        compressor.compress(out, linebreakpos, munge, verbose,
                                preserveAllSemiColons, disableOptimizations);
                        out.close();

                    } catch (EvaluatorException e) {

                        System.out.println("failed minifying... " + e);
                        // Return a special error code used specifically by the web front-end.
                        System.exit(2);

                    }

                } else if (f.getName().toLowerCase().endsWith(".css")) { //css
                    in = new FileReader(f);
                    System.out.println("_____________________________________________");
                    System.err.println("--- Minifying CSS: " + f.getAbsolutePath());
                    CssCompressor cssCompressor=null;
                    try{
                        cssCompressor = new CssCompressor(in);
                    }catch (Exception exp){
                        exp.printStackTrace();
                    }
                    // Close the input stream first, and then open the output stream,
                    // in case the output file should override the input file.
                    in.close();
                    in = null;

                    out = new FileWriter(f);

                    cssCompressor.compress(out, 0);
                    out.close();
                } else {
                    StringBuilder contents = new StringBuilder();

                    try {
                        //use buffering, reading one line at a time
                        //FileReader always assumes default encoding is OK!
                        BufferedReader input = new BufferedReader(new FileReader(f));
                        try {
                            String line = null;
                            while ((line = input.readLine()) != null) {
                                contents.append(line);
                                contents.append(System.getProperty("line.separator"));
                            }
                        } finally {
                            input.close();
                        }
                    } catch (IOException ex) {
                        System.out.println("exception");
                        ex.printStackTrace();
                    }

                    System.out.println("_____________________________________________");
                    System.err.println("--- Minifying HTML: " + f.getAbsolutePath());
                    HtmlCompressor htmlCompressor = new HtmlCompressor();

                    htmlCompressor.setEnabled(true);                   //if false all compression is off (default is true)
                    htmlCompressor.setRemoveComments(false);            //if false keeps HTML comments (default is true)
                    htmlCompressor.setRemoveMultiSpaces(true);         //if false keeps multiple whitespace characters (default is true)
                    htmlCompressor.setRemoveIntertagSpaces(true);      //removes iter-tag whitespace characters
                    htmlCompressor.setRemoveQuotes(false);              //removes unnecessary tag attribute quotes
                    htmlCompressor.setCompressCss(true);               //compress css using Yahoo YUI Compressor
                    htmlCompressor.setCompressJavaScript(true);        //compress js using Yahoo YUI Compressor
                    htmlCompressor.setYuiCssLineBreak(80);             //--line-break param for Yahoo YUI Compressor
                    htmlCompressor.setYuiJsDisableOptimizations(false); //--disable-optimizations param for Yahoo YUI Compressor
                    htmlCompressor.setYuiJsLineBreak(80);              //--line-break param for Yahoo YUI Compressor
                    htmlCompressor.setYuiJsNoMunge(true);              //--nomunge param for Yahoo YUI Compressor
                    htmlCompressor.setYuiJsPreserveAllSemiColons(false);//--preserve-semi param for Yahoo YUI Compressor

                    /* Sets default error reporting for YUI compressor that uses System.err.
                    If no error reporter is provided, a null pointer exception
                    will be thrown in case of an error during JavaScript compression.
                    This is needed only if JavaScript compression is enabled */
                    htmlCompressor.setYuiErrorReporter(new DefaultErrorReporter());
                    String compressedHtml = htmlCompressor.compress(contents.toString());
                    out = new FileWriter(f);
                    out.write(compressedHtml);
                    out.close();

                }
            }

        } catch (CmdLineException e) {
            // if there's a problem in the command line,
            // you'll get this exception. this will report
            // an error message.
            System.err.println(e.getMessage());
            System.err.println("java -jar SCCompiler.jar [options...] arguments...");
            // print the list of available options
            parser.printUsage(System.err);
            System.err.println();

            // print option sample. This is useful some time
            System.err.println("  Example: java -jar SCCompiler.jar" + parser.printExample(ALL));
            return;
        } catch (Exception ex) {
                   System.out.println("exception");
                 ex.printStackTrace();
        }
        // this will redirect the output to the specified output
        //System.out.println(out);
    }

    public static void visitAllDirsAndFiles(File dir, ArrayList<File> files) {
        if (dir.isDirectory()) {
            String[] children = dir.list();
            for (int i = 0; i < children.length; i++) {
                visitAllDirsAndFiles(new File(dir, children[i]), files);
            }
        } else {
            try {
                if (dir.getName().toLowerCase().endsWith(".js")) {
                    files.add(dir);
                } else if (dir.getName().toLowerCase().endsWith(".css")) {
                    files.add(dir);
                } else if (dir.getName().toLowerCase().endsWith(".html")) {
                    files.add(dir);
                }
            } catch (Exception e) {
                System.err.println(e);
            }

        }
        return;
    }
}
