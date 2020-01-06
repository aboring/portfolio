/*
 * Name: Andrew Boring
 * Computer Science 345
 * Homework #3
 * Professor Kobourov
 * Due: March 3rd, 2015
 */

/**
 * This class creates a SkipList that implements methods for insert,
 * remove and find.
 * 
 * @author Andrew Boring
 */

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Random;
import java.util.Scanner;

/**
 * This class creates a SkipList that implements methods for insert, delete, and
 * find.
 * 
 * @author Andrew Boring
 */

public class Skiplist {

	private int myMaxSize;
	private int mySize; // # of Nodes on the bottom level
	private Node myTop; // reference to highest level negative infinity node.
	private Node myTail; // reference to highest level positive infinity node.
	private int myLevels; // keeps track of how many levels this SkipList has.

	public static void main(String[] args) throws NumberFormatException,
			FileNotFoundException {
		Skiplist list = new Skiplist(Integer.parseInt(args[0]), args[1],
				Integer.parseInt(args[2]));
	}

	/**
	 * Creates the instance of SkipList, then scans an input file to insert
	 * into, find in, and remove from.
	 * 
	 * @param m
	 *            The maximum amount of Nodes allowed on the lowest level of
	 *            SkipList.
	 * 
	 * @param fileName
	 *            The name of the File to be Scanned.
	 * 
	 * @param seed
	 *            The seed for the Random instance.
	 * 
	 * @throws FileNotFoundException
	 */

	public Skiplist(int m, String fileName, int seed)
			throws FileNotFoundException {
		myMaxSize = m;
		mySize = 0;

		// setup head and tail nodes.
		Node tail = new Node(Integer.MAX_VALUE, null, null, 1);
		Node head = new Node(Integer.MIN_VALUE, tail, null, 1);

		myTop = head;
		myTail = tail;
		myLevels = 1;

		File file = new File(fileName);
		Scanner scan = new Scanner(file);

		String instruction;
		int input;

		while (scan.hasNext()) {
			instruction = scan.next();
			input = scan.nextInt();
			if (instruction.equalsIgnoreCase("insert"))
				System.out.println(insert(input, seed));
			else if (instruction.equalsIgnoreCase("find"))
				System.out.println(find(input));
			else if (instruction.equalsIgnoreCase("delete"))
				System.out.println(delete(input));
		}
		scan.close();

	}

	/**
	 * Inserts a Node into the Skiplist.
	 * 
	 * @param key
	 *            The value that the Node contains.
	 * 
	 * @param seed
	 *            The seed value for the Random instance.
	 * 
	 * @return boolean
	 */
	public boolean insert(int key, int seed) {
		if (mySize >= myMaxSize)
			return false;

		// I calculate the number of Node promotions before I ever try to add
		// the Node.
		int heads = 0;
		Random r = new Random(seed);
		while (r.nextBoolean() == true)
			heads++;

		// if a Node gets promoted higher than the number of levels
		// promote myHead and myTail first.
		while (myLevels < heads + 1) {
			myLevels++;
			Node newTail = new Node(myTail.getKey(), null, myTail, myLevels);
			Node newTop = new Node(myTop.getKey(), newTail, myTop, myLevels);
			myTop = newTop;
			myTail = newTail;
		}

		// find the place the highest copy of the node
		Node current = myTop;
		while (current.getLevel() > heads + 1) {
			while (current.getNext().getKey() < key) {
				current = current.getNext();
			}
			current = current.getBelow();
		}
		while (current.getNext().getKey() < key)
			current = current.getNext();

		// add at Node's highest level
		Node newNode = new Node(key, current.getNext(), null,
				current.getLevel());
		current.setNext(newNode);

		// add all Node's below until the bottom
		Node newCopy = newNode;
		while (heads > 0) {
			current = current.getBelow();
			while (current.getNext().getKey() < key)
				current = current.getNext();
			Node newCreate = new Node(key, current.getNext(), null,
					current.getLevel());
			newCopy.setBelow(newCreate);
			current.setNext(newCreate);
			newCopy = newCopy.getBelow();
			heads--;
		}
		mySize++;
		return true;
	}

	/**
	 * Finds a node in the SkipList.
	 * 
	 * @param key
	 *            The value of the Node we want to find.
	 * 
	 * @return boolean
	 */
	public boolean find(int key) {
		Node current = myTop;
		while (current.getBelow() != null) {
			while (current.getNext().getKey() <= key)
				current = current.getNext();
			current = current.getBelow();
		}
		while (current.getNext().getKey() <= key)
			current = current.getNext();

		if (current.getKey() == key)
			return true;
		return false;
	}

	/**
	 * This node is a copy of find() that was modified to return the actual Node
	 * itself, instead of a boolean. This allows it to be used in delete().
	 * 
	 * @param key
	 * @return
	 */
	private Node findBeforeAction(int key) {
		Node current = myTop;
		while (current.getBelow() != null) {
			while (current.getNext().getKey() < key)
				current = current.getNext();
			if (current.getNext().getKey() == key)
				break;
			current = current.getBelow();
		}

		while (current.getNext().getKey() < key)
			current = current.getNext();
		return current;
	}

	/**
	 * Deletes a Node from the SkipList.
	 * 
	 * @param key
	 *            The value of the Node we want to delete.
	 * 
	 * @return boolean
	 */

	public boolean delete(int key) {
		Node current = findBeforeAction(key);
		// current is now before the appropriate node

		if (current.getNext().getKey() != key)
			return false;

		while (current != null) {
			if (current.getNext().getKey() == key) {
				current.setNext(current.getNext().getNext());
				current = current.getBelow();
			} else
				while (current.getNext().getKey() < key) {
					current = current.getNext();
				}

		}
		mySize--;
		return true;
	}

	/**
	 * Returns a String representation of the SkipList.
	 * 
	 * @return String
	 */
	public String toString() {

		String toReturn = "";
		Node head = myTop;
		Node curr = head;
		do {
			while (curr.getNext() != null) {
				toReturn += "(" + curr.getKey() + ")---";
				curr = curr.getNext();
			}
			toReturn += "(" + curr.getKey() + ")\n";
			head = head.getBelow();
			curr = head;
		} while (curr != null);
		return toReturn;

	}

	/**
	 * This class creates Nodes to use in the Skiplist
	 * 
	 * @author Andrew Boring
	 */

	private class Node {

		private int myKey; // the value the Node contains.
		private Node myNext; // reference to next Node.
		private Node myBelow; // reference to the Node below.
		private int myLevel; // the level of the Node.

		/**
		 * Creates a node with the key value.
		 * 
		 * @param key
		 *            The value the Node will hold.
		 */
		private Node(int key) {
			setKey(key);
			setNext(null);
			setBelow(null);
			setLevel(1);
		}

		/**
		 * Creates a node with key, next, below and level.
		 * 
		 * @param key
		 *            The value the Node will hold.
		 * 
		 * @param next
		 *            The Node this Node will point right at.
		 * 
		 * @param below
		 *            The Node below this Node.
		 * 
		 * @param level
		 *            The level of this Node.
		 */
		private Node(int key, Node next, Node below, int level) {
			setKey(key);
			setNext(next);
			setBelow(below);
			setLevel(level);
		}

		// returns key
		private int getKey() {
			return myKey;
		}

		// returns next
		private Node getNext() {
			return myNext;
		}

		// returns below
		private Node getBelow() {
			return myBelow;
		}

		// returns level
		private int getLevel() {
			return myLevel;
		}

		// sets key
		private void setKey(int key) {
			myKey = key;
		}

		// sets next
		private void setNext(Node next) {
			myNext = next;
		}

		// sets below
		private void setBelow(Node below) {
			myBelow = below;
		}

		// sets level
		private void setLevel(int level) {
			myLevel = level;
		}

	}

}
