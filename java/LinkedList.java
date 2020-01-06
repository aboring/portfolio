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
 * This class creates a LinkedList that implements methods for insert, delete,
 * and find.
 * 
 * @author Andrew Boring
 */

public class LinkedList {

	private int myMaxSize;
	private int mySize;
	private Node myHead;

	public static void main(String[] args) throws NumberFormatException,
			FileNotFoundException {
		LinkedList list = new LinkedList(Integer.parseInt(args[0]), args[1]);
	}

	/**
	 * Creates the instance of LinkedList, then scans an input file to insert
	 * into, find in, and remove from.
	 * 
	 * @param m
	 *            The maximum size allowed for the LinkedList
	 * 
	 * @param fileName
	 *            The name of the File to be Scanned
	 * 
	 * @throws FileNotFoundException
	 */

	public LinkedList(int m, String fileName) throws FileNotFoundException {
		myMaxSize = m;
		mySize = 0;
		myHead = null;

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
	 * Inserts a node containing the key into the LinkedList
	 * 
	 * @param key
	 *            The value the Node contains.
	 * 
	 * @return boolean
	 */

	public boolean insert(int key) {
		if (mySize >= myMaxSize) {
			return false;
		}

		Node newNode = new Node(key);
		newNode.setNext(myHead);
		myHead = newNode;
		mySize++;
		return true;
	}

	/**
	 * Finds the Node that contains the value "key"
	 * 
	 * @param key
	 *            The value the Node you want to find should have.
	 * 
	 * @return boolean
	 */

	public boolean find(int key) {
		if (mySize == 0)
			return false;

		Node current = myHead;
		while (current != null)
			if (current.getKey() == key)
				return true;
			else
				current = current.getNext();

		return false;
	}

	/**
	 * Deletes the first Node that has this "key"
	 * 
	 * @param key
	 *            The value to search for.
	 * 
	 * @return boolean
	 */

	public boolean delete(int key) {
		if (mySize == 0)
			return false;

		Node current = myHead;
		if (myHead.getKey() == key) {
			myHead = myHead.getNext();
			mySize--;
			return true;
		}

		while (current.getNext() != null) {
			if (current.getNext().getKey() == key) {
				current.setNext(current.getNext().getNext());
				mySize--;
				return true;
			}
			current = current.getNext();
		}
		return false;
	}

	/**
	 * Returns a String representation of the LinkedList
	 * 
	 * @return String
	 */
	public String toString() {
		String toReturn = "";

		for (Node nd = myHead; nd != null; nd = nd.getNext()) {
			toReturn += "[" + nd.getKey() + "]";
		}

		return toReturn;
	}

	/**
	 * This class creates Nodes to use in the LinkedList
	 * 
	 * @author Andrew Boring
	 */

	private class Node {

		private int myKey;
		private Node myNext;

		/**
		 * Creates the Node
		 * 
		 * @param key
		 *            The value the Node will contain.
		 */
		public Node(int key) {
			setKey(key);
			setNext(null);
		}

		// returns the Node's key
		public int getKey() {
			return myKey;
		}

		// returns the Node's next
		public Node getNext() {
			return myNext;
		}

		// sets the Node's key
		public void setKey(int key) {
			myKey = key;
		}

		// sets the Node's next
		public void setNext(Node next) {
			myNext = next;
		}
	}

}
