/**
 * @fileoverview A simple Java script for a basic web crawler/scraper.
 * This script demonstrates how to fetch HTML content from a URL and
 * extract the page title.
 *
 * To run this script in VS Code:
 * 1. Save the code as `WebScraper.java`.
 * 2. Make sure you have the Java Development Kit (JDK) installed.
 * 3. Open the file in VS Code.
 * 4. Use the "Run" button/link above the `main` method, or open the terminal
 * (Ctrl+`) and compile then run manually:
 * javac WebScraper.java
 * java WebScraper <URL_to_scrape>
 *
 * Example Usage:
 * java WebScraper https://www.example.com
 * java WebScraper https://www.google.com
 */

import java.io.BufferedReader;   // Used for reading text from an input stream
import java.io.InputStreamReader; // Used for converting byte streams to character streams
import java.net.URL;              // Used for representing a Uniform Resource Locator
import java.util.regex.Matcher;   // Used for performing match operations on a character sequence
import java.util.regex.Pattern;   // Used for compiling regular expressions

public class WebScraper {

    /**
     * The main method is the entry point for the web scraper application.
     * It expects a URL as a command-line argument.
     * @param args Command-line arguments. The first argument should be the URL.
     */
    public static void main(String[] args) {
        // Check if a URL argument is provided.
        if (args.length == 0) {
            System.out.println("Usage: java WebScraper <URL_to_scrape>");
            System.out.println("Example: java WebScraper https://www.example.com");
            return; // Exit if no URL is provided.
        }

        String urlString = args[0]; // Get the URL from the first command-line argument.
        System.out.println("Attempting to scrape: " + urlString);
        System.out.println("------------------------------------");

        try {
            // 1. Create a URL object from the provided string using URI to avoid deprecated constructor.
            URL url = java.net.URI.create(urlString).toURL();

            // 2. Open a connection to the URL and get an InputStream.
            // InputStreamReader converts the byte stream from the URL connection into a character stream.
            // BufferedReader wraps the InputStreamReader for efficient reading line by line.
            StringBuilder htmlContent = new StringBuilder(); // To build the entire HTML content.
            String line;
            int lineCount = 0; // Counter to limit printing of raw HTML lines.

            // 3. Read the HTML content line by line using try-with-resources.
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(url.openStream()))) {
                while ((line = reader.readLine()) != null) {
                    htmlContent.append(line).append("\n"); // Append each line and a newline character.
                    // Print only the first few lines to avoid overwhelming the console.
                    if (lineCount < 10) {
                        System.out.println(line);
                    } else if (lineCount == 10) {
                        System.out.println("...(truncated for brevity)");
                    }
                    lineCount++;
                }
            } // reader is automatically closed here

            System.out.println("------------------------------------");
            System.out.println("HTML content fetched successfully.");

            // 4. Extract the page title using a regular expression.
            // The pattern looks for <title>...</title> tags, capturing the content inside.
            Pattern titlePattern = Pattern.compile("<title>(.*?)</title>", Pattern.CASE_INSENSITIVE | Pattern.DOTALL);
            Matcher matcher = titlePattern.matcher(htmlContent.toString());

            if (matcher.find()) {
                // If a title is found, group(1) refers to the content captured by (.*?).
                String pageTitle = matcher.group(1).trim();
                System.out.println("Page Title: " + pageTitle);
            } else {
                System.out.println("Page Title: Not found.");
            }

        } catch (java.net.MalformedURLException e) {
            // Handle cases where the URL is not valid.
            System.err.println("Error: Invalid URL format. " + e.getMessage());
        } catch (java.io.IOException e) {
            // Handle I/O errors (e.g., network issues, server not found).
            System.err.println("Error fetching URL content: " + e.getMessage());
        } catch (Exception e) {
            // Catch any other unexpected errors.
            System.err.println("An unexpected error occurred: " + e.getMessage());
            //            e.printStackTrace(); // Print the stack trace for debugging.
        }
    }
}
