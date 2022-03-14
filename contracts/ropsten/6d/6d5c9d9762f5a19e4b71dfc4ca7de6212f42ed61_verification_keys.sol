/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
//---------------------------------------------------------------------------//
// Copyright (c) 2018-2021 Mikhail Komarov <[email protected]>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//---------------------------------------------------------------------------//

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/**
 * @title Bn254Crypto library used for the fr, g1 and g2 point types
 * @dev Used to manipulate fr, g1, g2 types, perform modular arithmetic on them and call
 * the precompiles add, scalar mul and pairing
 *
 * Notes on optimisations
 * 1) Perform addmod, mulmod etc. in assembly - removes the check that Solidity performs to confirm that
 * the supplied modulus is not 0. This is safe as the modulus's used (r_mod, q_mod) are hard coded
 * inside the contract and not supplied by the user
 */
library types {
    uint256 constant PROGRAM_WIDTH = 4;
    uint256 constant NUM_NU_CHALLENGES = 11;

    uint256 constant coset_generator0 = 0x0000000000000000000000000000000000000000000000000000000000000005;
    uint256 constant coset_generator1 = 0x0000000000000000000000000000000000000000000000000000000000000006;
    uint256 constant coset_generator2 = 0x0000000000000000000000000000000000000000000000000000000000000007;

    // TODO: add external_coset_generator() method to compute this
    uint256 constant coset_generator7 = 0x000000000000000000000000000000000000000000000000000000000000000c;

    struct g1_point {
        uint256 x;
        uint256 y;
    }

    // G2 group element where x \in Fq2 = x0 * z + x1
    struct g2_point {
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
    }

    // N>B. Do not re-order these fields! They must appear in the same order as they
    // appear in the proof data
    struct proof {
        g1_point W1;
        g1_point W2;
        g1_point W3;
        g1_point W4;
        g1_point Z;
        g1_point T1;
        g1_point T2;
        g1_point T3;
        g1_point T4;
        uint256 w1;
        uint256 w2;
        uint256 w3;
        uint256 w4;
        uint256 sigma1;
        uint256 sigma2;
        uint256 sigma3;
        uint256 q_arith;
        uint256 q_ecc;
        uint256 q_c;
        uint256 linearization_polynomial;
        uint256 grand_product_at_z_omega;
        uint256 w1_omega;
        uint256 w2_omega;
        uint256 w3_omega;
        uint256 w4_omega;
        g1_point PI_Z;
        g1_point PI_Z_OMEGA;
        g1_point recursive_P1;
        g1_point recursive_P2;
        uint256 quotient_polynomial_eval;
    }

    struct challenge_transcript {
        uint256 alpha_base;
        uint256 alpha;
        uint256 zeta;
        uint256 beta;
        uint256 gamma;
        uint256 u;
        uint256 v0;
        uint256 v1;
        uint256 v2;
        uint256 v3;
        uint256 v4;
        uint256 v5;
        uint256 v6;
        uint256 v7;
        uint256 v8;
        uint256 v9;
        uint256 v10;
    }

    struct verification_key {
        uint256 circuit_size;
        uint256 num_inputs;
        uint256 work_root;
        uint256 domain_inverse;
        uint256 work_root_inverse;
        g1_point Q1;
        g1_point Q2;
        g1_point Q3;
        g1_point Q4;
        g1_point Q5;
        g1_point QM;
        g1_point QC;
        g1_point QARITH;
        g1_point QECC;
        g1_point QRANGE;
        g1_point QLOGIC;
        g1_point SIGMA1;
        g1_point SIGMA2;
        g1_point SIGMA3;
        g1_point SIGMA4;
        bool contains_recursive_proof;
        uint256 recursive_proof_indices;
        g2_point g2_x;

        // zeta challenge raised to the power of the circuit size.
        // Not actually part of the verification key, but we put it here to prevent stack depth errors
        uint256 zeta_pow_n;
    }
}

library redshift_vk {
    function get_verification_key() internal pure returns (types.verification_key memory) {
        types.verification_key memory vk;

        assembly {
            mstore(add(vk, 0x00), 524288) // vk.circuit_size
            mstore(add(vk, 0x20), 26) // vk.num_inputs
            mstore(add(vk, 0x40), 0x2260e724844bca5251829353968e4915305258418357473a5c1d597f613f6cbd) // vk.work_root
            mstore(add(vk, 0x60), 0x3064486657634403844b0eac78ca882cfd284341fcb0615a15cfcd17b14d8201) // vk.domain_inverse
            mstore(add(vk, 0x80), 0x06e402c0a314fb67a15cf806664ae1b722dbc0efe66e6c81d98f9924ca535321) // vk.work_root_inverse
            mstore(mload(add(vk, 0xa0)), 0x1a3423bd895e8b66e96de71363e5c424087c0e04775ef8b42a367358753ae0f4)//vk.Q1
            mstore(add(mload(add(vk, 0xa0)), 0x20), 0x2894da501e061ba9b5e1e1198f079425eebfe1a2bba51ba4fa8b76df1d1a73c8)
            mstore(mload(add(vk, 0xc0)), 0x27bb9587702025db4eb9dba04b9abfcca1aa16a24a4692e90ff4197208ba21a9)//vk.Q2
            mstore(add(mload(add(vk, 0xc0)), 0x20), 0x1974fa1e729ab0d97ad38bd1c212617f9f2fdda1ef38ad6571549992b9f512a2)
            mstore(mload(add(vk, 0xe0)), 0x05c63dff9ea6d84930499309729d82697af5febfc5b40ecb5296c55ea3f5e179)//vk.Q3
            mstore(add(mload(add(vk, 0xe0)), 0x20), 0x270557e99250f65d4907e9d7ee9ebcc791712df61d8dbb7cadfbf1358049ce83)
            mstore(mload(add(vk, 0x100)), 0x2f81998b3f87c8dd33ffc072ff50289c0e92cbcd570e86902dbad50225661525)//vk.Q4
            mstore(add(mload(add(vk, 0x100)), 0x20), 0x0d7dd6359dbffd61df6032f827fd21953f9f0c73ec02dba7e1713d1cbefe2f71)
            mstore(mload(add(vk, 0x120)), 0x14e5eedb828b93326d1eeae737d816193677c3f57a0fda32c839f294ee921852)//vk.Q5
            mstore(add(mload(add(vk, 0x120)), 0x20), 0x0547179e2d2c259f3da8b7afe79a8a00f102604b630bcd8416f099b422aa3c0d)
            mstore(mload(add(vk, 0x140)), 0x09336d18b1e1526a24d5f533445e70f4ae2ad131fe034eaa1dad6c40d42ff9b5)//vk.QM
            mstore(add(mload(add(vk, 0x140)), 0x20), 0x04f997d41d2426caad28b1f32313d345bdf81ef4b6fcc80a273cb625e6cd502b)
            mstore(mload(add(vk, 0x160)), 0x137bc4cd7621f6d9eaa4c76f6070e28d09a0ba81e56e413b9047200bd318854f)//vk.QC
            mstore(add(mload(add(vk, 0x160)), 0x20), 0x1edf634bc8e7ff5495012ce1368bdab088b6f972095de12d920154c64295ab28)
            mstore(mload(add(vk, 0x180)), 0x080189f596dddf5feda887af3a2a169e1ea8a69a65701cc150091ab5b4a96424)//vk.QARITH
            mstore(add(mload(add(vk, 0x180)), 0x20), 0x16d74168928caaa606eeb5061a5e0315ad30943a604a958b4154dae6bcbe2ce8)
            mstore(mload(add(vk, 0x1a0)), 0x0bea205b2dc3cb6cc9ed1483eb14e2f1d3c8cff726a2e11aa0e785d40bc2d759)//vk.QECC
            mstore(add(mload(add(vk, 0x1a0)), 0x20), 0x19ee753b148189d6877e944c3b193c38c42708585a493ee0e2c43ad4a9f3557f)
            mstore(mload(add(vk, 0x1c0)), 0x2db2e8919ea4292ce170cff4754699076b42af89b24e148cd6a172c416b59751)//vk.QRANGE
            mstore(add(mload(add(vk, 0x1c0)), 0x20), 0x2bf92ad75a03c4f401ba560a0b3aa85a6d2932404974b761e6c00cc2f2ad26a8)
            mstore(mload(add(vk, 0x1e0)), 0x2126d00eb70b411bdfa05aed4e08959767f250db6248b8a20f757a6ec2a7a6c6)//vk.QLOGIC
            mstore(add(mload(add(vk, 0x1e0)), 0x20), 0x0bd3275037c33c2466cb1717d8e5c8cf2d2bb869dbc0a10d73ed2bea7d3e246b)
            mstore(mload(add(vk, 0x200)), 0x0ffe38e772df83946d748796cc084a82b48256f079cca66195a91507162d3269)//vk.SIGMA1
            mstore(add(mload(add(vk, 0x200)), 0x20), 0x150597d86cbef95be2421df1c888fff5dc553bdedf96ce05f3ab6166b779113c)
            mstore(mload(add(vk, 0x220)), 0x097dd0e2a921a8ba163b4a5eff4788ca569f446e7fb4c293f3fb6636fde6b0ab)//vk.SIGMA2
            mstore(add(mload(add(vk, 0x220)), 0x20), 0x0251a0a84f54f1d726f97517e3b365c7f0744ad91b6301700bf8b6a4f40a2104)
            mstore(mload(add(vk, 0x240)), 0x229d17f3ba3fe020cb02be60ae11a9a9cc5b625240edd6af8c21689af9d9e4f5)//vk.SIGMA3
            mstore(add(mload(add(vk, 0x240)), 0x20), 0x2408b183ac099721fe9ddfb0c51c1c7d6305441aefdc1510d306027f22000f70)
            mstore(mload(add(vk, 0x260)), 0x1d928372dc4405e422924f1750369a62320422208422c7a8ddf22510fe3301a3)//vk.SIGMA4
            mstore(add(mload(add(vk, 0x260)), 0x20), 0x003f0e42598c2979879084939dd681db21471e29c009760079f8fde72ae59de4)
            mstore(add(vk, 0x280), 0x00) // vk.contains_recursive_proof
            mstore(add(vk, 0x2a0), 0) // vk.recursive_proof_public_input_indices
            mstore(mload(add(vk, 0x2c0)), 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1) // vk.g2_x.X.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x20), 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0) // vk.g2_x.X.c0
            mstore(add(mload(add(vk, 0x2c0)), 0x40), 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4) // vk.g2_x.Y.c1
            mstore(add(mload(add(vk, 0x2c0)), 0x60), 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55) // vk.g2_x.Y.c0
        }
        return vk;
    }
}

/**
 * @title Verification keys library
 * @dev Used to select the appropriate verification key for the proof in question
 */
library verification_keys {
    /**
     * @param _keyId - verification key identifier used to select the appropriate proof's key
     * @return Verification key
     */
    function getKeyById(uint256 _keyId) external pure returns (types.verification_key memory) {
        // added in order: qL, qR, qO, qC, qM. x coord first, followed by y coord
        types.verification_key memory vk;

        if (_keyId == 0) {
            vk = redshift_vk.get_verification_key();
        }
        return vk;
    }
}