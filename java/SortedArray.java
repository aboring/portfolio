/*
 * Name: Andrew Boring
 * Computer Science 345
 * Homework #3
 * Professor Kobourov
 * Due: March 3rd, 2015
 */

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Scanner;

/**
 * This class creates a SortedArray that implements methods for insert, delete,
 * and find.
 * 
 * @author Andrew Boring
 */

public class SortedArray {

	private int[] ary;
	private int myMaxSize;
	private int mySize;

	public static void main(String[] args) throws NumberFormatException,
			FileNotFoundException {
		SortedArray ary = new SortedArray(Integer.parseInt(args[0]), args[1]);
	}

	/**
	 * Creates the instance of SortedArray, then scans an input file to insert
	 * into, find in, and remove from.
	 * 
	 * @param m
	 *            The maximum size allowed for the SortedArray, also the size of
	 *            the array it is created from.
	 * 
	 * @param fileName
	 *            The name of the File to be Scanned.
	 * 
	 * @throws FileNotFoundException
	 */

	public SortedArray(int m, String fileName) throws FileNotFoundException {

		myMaxSize = m;
		ary = new int[myMaxSize];
		mySize = 0;

		File file = new File(fileName);
		Scanner scan = new Scanner(file);

		String instruction;
		int input;

		while (scan.hasNext()) {
			instruction = scan.next();
			input = scan.nextInt();
			if (instruction.equalsIgnoreCase("insert"))
				System.out.println(insert(input));
			else if (instruction.equalsIgnoreCase("find"))
				System.out.println(find(input));
			else if (instruction.equalsIgnoreCase("delete"))
				System.out.println(delete(input));
		}
		scan.close();
	}

	/**
	 * Inserts the key into the SortedArray.
	 * 
	 * @param key
	 *            The value to be inserted.
	 * 
	 * @return boolean
	 */
	public boolean insert(int key) {
		if (mySize >= myMaxSize)
			return false;

		for (int i = mySize - 1; i >= 0; i--) {
			if (ary[i] <= key) {
				ary[i + 1] = key;
				mySize++;
				return true;
			} else {
				ary[i + 1] = ary[i];
			}
		}
		ary[0] = key;
		mySize++;
		return true;
	}

	/**
	 * Finds a value in the SortedArray.
	 * 
	 * @param key
	 *            The value to find.
	 * 
	 * @return boolean
	 */
	public boolean find(int key) {
		if (mySize == 0)
			return false;

		int l, r, m;
		l = 0;
		r = mySize - 1;
		while (l <= r) {
			m = (l + r) / 2;
			if (ary[m] == key)
				return true;
			else if (ary[m] > key)
				r = m - 1;
			else
				l = m + 1;
		}

		return false;
	}

	/**
	 * Deletes a value from the SortedArray.
	 * 
	 * @param key
	 *            The value to delete.
	 * 
	 * @return boolean
	 */

	public boolean delete(int key) {
		if (mySize <= 0)
			return false;
		// int i;
		boolean found = false;
		for (int i = 0; i < mySize; i++) {
			if (ary[i] == key) {
				found = true;
			} else if (found == false) {
				continue;
			} else {
				ary[i - 1] = ary[i];
			}
		}
		if (found == true) {
			mySize--;
		}
		return found;
	}

	/**
	 * Returns a String representation of the SortedArray.
	 * 
	 * @return String
	 */
	public String toString() {
		String toReturn = "";

		for (int i = 0; i < mySize; i++) {
			toReturn += "[" + ary[i] + "]";
		}

		return toReturn;
	}

}
