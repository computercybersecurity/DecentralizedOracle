pragma solidity >=0.4.21 <0.6.0;

import "./Randomizer.sol";

library Selection {

    struct Pair {
        uint256 id;
        uint256 value;
    }

    function quickSort(Pair[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].value;
        while (i <= j) {
            while (arr[uint256(i)].value < pivot) i++;
            while (pivot < arr[uint256(j)].value) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    function getSelectedOracles(uint256 n, uint256 m) external view returns (uint256[] memory) {
        Pair[] memory data;
        uint256[] memory res;
        uint256 i = 0;
        
        for (i = 0 ; i < n ; i ++) {
            data[i] = Pair(i, Randomizer.getRandom(n));
        }

        quickSort(data, int(0), int(data.length - 1));
        
        for (i = 0 ; i < m ; i ++) {
            res[i] = data[i].id;
        }

        return res;
    }
}