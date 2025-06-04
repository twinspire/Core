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
	public static function where<T>(arr:Array<T>, callback:(T) -> Bool):Iterable<T>
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
	public static function whereIndices<T>(arr:Array<T>, callback:(T) -> Bool):Iterable<Int>
	{
		var results = new Array<Int>();
		for (i in 0...arr.length)
		{
			if (callback(arr[i]))
				results.push(i);
		}

		return results;
	}

}