// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./Randomizer.sol";

contract Selection is Randomizer {

    struct Pair {
        uint id;
        uint value;
    }

    function quickSort(Pair[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].value;
        while (i <= j) {
            while (arr[uint(i)].value < pivot) i++;
            while (pivot < arr[uint(j)].value) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function getSelectedOracles(uint n) internal view returns (uint[] memory) {
        Pair[] memory data = new Pair[](n);
        uint[] memory res = new uint[](n);
        uint i = 0;
        
        for (i = 0 ; i < n ; i ++) {
            data[i] = Pair(i, getRandom(n));
        }

        quickSort(data, int(0), int(data.length - 1));
        
        for (i = 0 ; i < n ; i ++) {
            res[i] = data[i].id;
        }

        return res;
    }
}