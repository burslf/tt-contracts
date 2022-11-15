// "SPDX-License-Identifier: UNLICENSED"

pragma solidity >=0.6.0 <0.9.0;

/**
 * Array library.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

library Array {
    function removeElement(address[] storage _array, address _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}