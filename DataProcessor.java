/**
 * @fileoverview A simple Java script for data processing and transformation.
 * This script demonstrates basic string manipulation, list operations,
 * and conditional logic to process a list of names.
 *
 * To run this script in VS Code:
 * 1. Save the code as `DataProcessor.java`.
 * 2. Make sure you have the Java Development Kit (JDK) installed.
 * 3. Open the file in VS Code.
 * 4. Use the "Run" button/link above the `main` method, or open the terminal
 * (Ctrl+`) and compile then run manually:
 * javac DataProcessor.java
 * java DataProcessor
 */

import java.util.ArrayList; // Used for dynamic array (list) of strings
import java.util.Arrays;    // Used for converting array to list
import java.util.List;      // Interface for list
import java.util.stream.Collectors; // Used for stream operations like collecting results

public class DataProcessor {

    /**
     * The main method is the entry point for any Java application.
     * It contains the core logic for our data processing script.
     * @param args Command-line arguments (not used in this example).
     */
    public static void main(String[] args) {

        // 1. Define the raw input data as a single string.
        // This simulates receiving data from an external source or a file.
        String rawNamesData = "alice,bob,charlie,david,eve,frank,grace,helen,ivan";
        System.out.println("--- Original Raw Data ---");
        System.out.println("Raw String: \"" + rawNamesData + "\"");
        System.out.println("\n"); // Add a newline for better readability

        // 2. Process: Split the raw string into individual names.
        // The split() method divides this string into an array of substrings
        // based on the comma delimiter.
        String[] nameArray = rawNamesData.split(",");

        // Convert the array of names into a List for easier manipulation.
        // Lists are more flexible than arrays for adding/removing elements.
        List<String> namesList = new ArrayList<>(Arrays.asList(nameArray));

        System.out.println("--- Step 1: Split into List ---");
        System.out.println("Initial Names List: " + namesList);
        System.out.println("\n");

        // 3. Transform: Capitalize the first letter of each name.
        // We use a Java Stream for a concise way to transform each element.
        // .map() applies a function to each element.
        // .substring(0, 1).toUpperCase() gets the first char and makes it uppercase.
        // .substring(1) gets the rest of the string.
        // .collect(Collectors.toList()) gathers the results back into a new List.
        List<String> capitalizedNames = namesList.stream()
            .map(name -> name.substring(0, 1).toUpperCase() + name.substring(1))
            .collect(Collectors.toList());

        System.out.println("--- Step 2: Capitalize Names ---");
        System.out.println("Capitalized Names: " + capitalizedNames);
        System.out.println("\n");

        // 4. Filter: Keep only names that have 5 or more characters.
        // .filter() keeps only elements that satisfy a given condition.
        // name.length() >= 5 checks if the name's length is 5 or greater.
        List<String> filteredNames = capitalizedNames.stream()
            .filter(name -> name.length() >= 5)
            .collect(Collectors.toList());

        System.out.println("--- Step 3: Filter Names (Length >= 5) ---");
        System.out.println("Filtered Names: " + filteredNames);
        System.out.println("\n");

        // 5. Final Output: Display the final processed data.
        System.out.println("--- Final Processed Data ---");
        System.out.println("Original Count: " + namesList.size());
        System.out.println("Processed Count: " + filteredNames.size());
        System.out.println("Final List of Names: " + filteredNames);
    }
}
