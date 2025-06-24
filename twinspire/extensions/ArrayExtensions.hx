package twinspire.extensions;

class ArrayExtensions
{

	/**
	 * Return the first item that matches the given condition from a callback
	 * function.
	 */
	public static function find<T>(arr:Array<T>, callback:(T) -> Bool):T
	{
		for (i in 0...arr.length)
		{
			if (callback(arr[i]))
				return arr[i];
		}

		return null;
	}

	/**
	 * Return the first item's index that matches the given condition from a callback
	 * function.
	 */
	public static function findIndex<T>(arr:Array<T>, callback:(T) -> Bool):Int
	{
		for (i in 0...arr.length)
		{
			if (callback(arr[i]))
				return i;
		}

		return -1;
	}

	/**
	 * Return an `Array<T>` of all items that matches the given condition from a callback
	 * function.
	 */
	public static function where<T>(arr:Array<T>, callback:(T) -> Bool):Array<T>
	{
		var results = new Array<T>();
		for (i in 0...arr.length)
		{
			if (callback(arr[i]))
				results.push(arr[i]);
		}

		return results;
	}

	/**
	* Return an `Array<Int>` of indices of all items that matches the given condition from a callback
	* function.
	**/
	public static function whereIndices<T>(arr:Array<T>, callback:(T) -> Bool):Array<Int>
	{
		var results = new Array<Int>();
		for (i in 0...arr.length)
		{
			if (callback(arr[i]))
				results.push(i);
		}

		return results;
	}

	/**
	* Return a boolean value that determines if all of the elements meet the conditions of `onEach` from 
	* a given set of indices.
	**/
	public static function eachOf<T>(arr:Array<T>, ofIndices:Array<Int>, onEach:(T) -> Bool):Bool {
		if (arr.length == 0) {
			return false;
		}

		for (index in ofIndices) {
			var ok = onEach(arr[index]);
			if (!ok) {
				return false;
			}
		}

		return true;
	}

	/**
	* 
	**/
	public static function each<T>(arr:Array<T>, onEach:(T) -> Bool):Bool {
		if (arr.length == 0) {
			return false;
		}

		for (i in 0...arr.length) {
			var ok = onEach(arr[i]);
			if (!ok) {
				return false;
			}
		}

		return true;
	}

	/**
	* Return a boolean value that determines if any one of the elements meet the conditions of `onEach` from 
	* a given set of indices.
	**/
	public static function anyOf<T>(arr:Array<T>, ofIndices:Array<Int>, onEach:(T) -> Bool):Bool {
		if (arr.length == 0) {
			return false;
		}

		for (index in ofIndices) {
			var ok = onEach(arr[index]);
			if (ok) {
				return true;
			}
		}

		return false;
	}

	/**
	* 
	**/
	public static function any<T>(arr:Array<T>, onEach:(T) -> Bool):Bool {
		if (arr.length == 0) {
			return false;
		}

		for (i in 0...arr.length) {
			var ok = onEach(arr[i]);
			if (ok) {
				return true;
			}
		}

		return false;
	}

}