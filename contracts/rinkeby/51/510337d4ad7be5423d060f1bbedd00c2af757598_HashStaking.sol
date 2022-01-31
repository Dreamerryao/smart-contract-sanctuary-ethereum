// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TransferHelper.sol";

contract HashStaking is Ownable {
    address public hashTokenAddress;
    uint public proceedsLimit = 0;
    uint public maxPeriod = 40 * 60;
    uint public referralPercent = 10;
    bool public stakingFinished = false;

    address[] public earlyInvestors = [
        0x87B3307F8D004C921F4e1e7f62E446C15FD994d2,
        0xFc554C36d82b792B4d69Ec12d225AAF7179130B8,
        0x251100621c07e04168d7Cf107c6bC18C7B412b9D,
        0xCfb38D37F8Df2E89b967a4e2dbe070Afa7D540b7,
        0x69024Cc560BDc7f33399992B3796fE8044Fb517a,
        0x543368b99ca3A6a1f499678025749d741523b802,
        0x428D7320aA41C5490A183F449Fe7a0A32F0af8aD,
        0x0733eed9bc9EeDb0654d0D117e7e1167623668eF,
        0x6De3688bD9C2d59Ec9E2866CB643dd920003Fc48,
        0x193D252a648E1DA7D4A2B54950D2Fe9696f55541,
        0xD8bc928980def8a92E891CDf455e8D468e7A9c96,
        0x62058A952b38B651B1800317bf2e5bF92E154608,
        0xFE4065DB6BF17ad399254B3118F823D00302F9A0,
        0xDBDb47D07a6e34829e67d85cd235C9Cb3fe77DF5,
        0xD428C3e3F623380eB9eF89546ba1C367C0a5EcF9,
        0x98C91e73dEb976220B80906943aB5e0fB08B31cE,
        0xbFbCc50Ede71F36EF3f799439e345CEb2435857D,
        0xFe1F9fF719090b9900d096d2E78FfE8bfCd78D7B,
        0xDe606f4c8A156fC7a943CA629Fb9aa4f459Fb6f8,
        0xC6De062C1118a90Dd2559Aff5A9b91eE4953c8F8,
        0x2b0a0aAc717CeE44f33C068C37d1f5174B1aDC9d,
        0xe3E6e651d8f9C80B6BB16ff3E8637dD0c1B677bB,
        0x0FD0494d179efe47112C321CE2fC13Ace732ecc7,
        0x096E604B33B7D77e7689CC81001aEEa7A8601B63,
        0x3978AE125aadFe5F0bF2819E14Ed4154c2Fb5182,
        0x4B534D640e1122810f37f7c1B5a16A25636A3131,
        0xA5979f35Bee755905233Bf3b908055917312DF38,
        0x69a263804BC8Ea966095eA21aea58b9eA6Bf52A7,
        0x2e6C17831870CddA3B0f4824267208f785Fe042C,
        0x5995aDbB7f42cF1815ab9672A70Ff0eC30bcDdAb,
        0x805B3599D0C8Cbf09aD8505F6C7CE9786A173EbC,
        0x5cb3CA70fCC097AE9c439941482CfB4fD62f319a,
        0x776C24Dd0a67334702B9D4835feC44CAE0d1bc11,
        0x5171049F170C9EE4AFb26E565B8e20eB25eeD99c,
        0x36964318EED56688100CE875441F4093C18bDBe0,
        0x6CDE5374EFd2aE9cB4b1C6a215B33EDa29E28faF,
        0xb4E5B4a2208A9Fe169aCD385105980aA59a62663,
        0xB5599d9ef7659b0DCB58ea042700B4D79e2bD9a1,
        0xdfe313f00157f31EF0E10F1C862224904Ebf0f13,
        0xc50A1834a5A1aeF4c95ED1999BdeE32a5348C526,
        0x0A6501762ADD2292B79F42Cafc544268905DEE1A,
        0x0D9b7C19CF1A55ABD4458634752751840576156c,
        0x1fC452e6c6E46A803E712126aD544430D9719767,
        0xC59678b23012e1D2299ea4903DC16676C88f10ba,
        0xe6A3794283732A6E4B8462Aa8121989878Be9c31,
        0xbA6aD83576eF09AF95e5F07F0ec1FDfA5e6E261d,
        0xe297967423400Ad25a5D23fC269fAA076f73c36A,
        0xB812e553048ad7A10A4193A28B69eCA880CaBeEf,
        0x52c1FA2280F1773b7B0B42E499D5D3Eb28892Da8,
        0x6410f8C356475332f93e3B6CedCa79c7b4370E24,
        0xa39d176F5f260afd91CF86107533afD6Ed45014E,
        0xe6Ad213CdA44E8c76c304ddd31d64e390e1ea28F,
        0x63A8b6413e4C68f33E6De208648735f28C38dD7f,
        0x056C7a4cF33f91E8734185787F1232dA19d61F6b,
        0x05F7556f76620aED533e68BDC5e21775cdc1fEF7,
        0x071206d2fB1F97EF8c7f79303a44e231674Ded11,
        0x4FfB89a61A6dB0586AFF308EFcfCe39207AEd2B2,
        0x434599d3005c1FE1345E1A85F9b429EB1ceb09D8,
        0xac254eAC0Ab97cA367e0b48ECaEfA79C626116Db,
        0x86228c704C2187170772AdE20a4EB0CE57bf49D6,
        0xd31Dc0033bc653610fAaFa8A095345de81266C68,
        0x180ad2D589835EB3a206D69ca024fDdB28eE81c0,
        0x3312FFfF12c8309419154ABe669a4C375213A7C2,
        0xa6BCe462B9AD0B045dd37dbDc604aca4b1a3Da70,
        0x12Cf5F7A4c3E10b0dAc3aa16a38fFB06bB8d5d4c,
        0x41C27C040Ec30665aC14a4B7481C121cb33a2F9c,
        0x254da1662B450A87fE9DCcbEab2ADf37787E3cAb,
        0x5132F1F89d070a8DD653B03Fa3E3d4e9EB425b80,
        0x0968Aa642f513C196763Eb82cc1f756319C33F73,
        0x78386fD769064Fe328bFA5b87312F7aDbB057509,
        0xb0C7331470Dc785E92bb64e7af72d24304fd8E0f,
        0x1CD52395ede36192d079d828a6b01300fa1817bD,
        0x44f43F5d92EB7901BA52cE7fd68A760C2dBe8434,
        0xBF5dBddd07504cA46c064cf0475089791a0aAC74,
        0xfCCeB7E4e236450Fdfae44c6689FDd89a0F53578,
        0xbc49618827f9182e5Ff5c6A40e43816a791105a4,
        0xCA546d2c7148DFc239515F9C8192f38b5789e42F,
        0xe083d454bd78536708eBba19dFb276c058f370CD,
        0x6B6694ba075b6fA6040CA7219F2ae1c8Ed537A55,
        0xa1BBb5447E797a5D5C49222D51213B2063946801,
        0x07CBa5Da40B8b853989c4Ea440CFc7be693E34be,
        0xB52Dd1cF20641327f1DcC6e7E4763337FFFF0c1b,
        0xD6a96319F0dbC70fFd439aF4A99480aE726393BD,
        0x40C650810fA3a324d01108CAf1B4534d5795ceF2,
        0x779DA642B0386E94971316AcB0A2d140F9a18372,
        0x26d005a25c7E0d6aD74f758005A57D8D40f3bEF2,
        0x739282714472cE30388F343d8C69ecF7E72F9EcD,
        0x601c4DF8774069b14375c32B6DFb9D4b03c9d070,
        0xAA60d5ce77DCF80C631C164D37aA23FAb641D304,
        0xbbC88585a175991944D8498D7ada58C9416a6647,
        0x1CAf1721c38AB85CE89e565a6A04366287202832,
        0x16CeF1F8147E6AfB7CdD246E8C7Bcb41AA45b3D4,
        0x57882a6760E8074dcAFa71EDA512e5797d2390B0,
        0x6F67d3C0723D6Aeb5963B1791C812B61f9B07741,
        0xF6D8545f77E6C5FBDf596f2f83C5a4fc98924E76,
        0x630685a0C32c03F289c369A4d4aBbF9833648296,
        0xC29695F44466B7F8B4eF2E51b816E3Ff3d89CfdC,
        0x3E80a9B760d15a787DC16460D60E419ED44de5e9,
        0xD8A6b8C5f272D41BE77Da0c7c15683D27834f06B,
        0xf4ce65c84Bb54E53fEa3Cd839Fe62200F7E61979,
        0x9d2a733e182a4ff774e45278a9c504A4Fd942a7E,
        0x48d909a00a3344e60AADFB9E122682082d51a045,
        0x4f08C8955682fbF4fbfF1F404758d3CdE1A9d9dF,
        0xeCDd677DAaCF48db8d4CC0968C9AA0f3322fcD1b,
        0xB34887e8C0964093BaBbA3D3148f3137496b162c,
        0x5761bE632337707809383f0920b037d8b0B6C395,
        0xE916C7704Acbf862D3EA09ecbc2a14F4D66Fe9b1,
        0x1DE8933644884BDdE909E71EFd367b2fdc4FBd87,
        0x084b7274fe951f590bcBca3cf67d59A9e088A50e,
        0x3d3C61789Fa889eec31eFb7EdBf88C46A63728e1,
        0x625c3D740389A0bC3eB2fd685e920D2cDC97AC49,
        0xf6aCeACD9FA557F192D99F99CA47134D5c1BaEa2,
        0x28FF6D137370Dcf663f73f19F1F219755cbf860D,
        0xa01d15E9Cb6045e22C698F9037FBe5AFC3Bb8a4C,
        0x5e48bb9C1A1a4484cf67a322Cd3A607767257D24,
        0x2C9A548Fa079269ec64c9ABF8c69112c582185eB,
        0x8111Ebf37362D37627a724e8Ae5799F95855a7AF,
        0xB46d77D366a8c3CEED76Bf0Fb04A837DD6D2C1B1,
        0x99bD6FD9d9E0A4E82e9F8fbe9008c31a25C6204c,
        0x0b7C75A9689A84854256c7d5dB7C87fEB1bbbb8b,
        0x3393dc1697B5728f2A8D740f4119dfC144AfF657,
        0xD7750fA148aC6E645a39150cB1C013a33e9ef5c0,
        0x0cDB94264183Ada72C197F37Fa2e4546479C0883,
        0x31DE34A9CdfA3690997d89989738b22460EA2175,
        0x48897529f2857A6687c8624615A17c8e0b90fCD1,
        0xD9eDF3a8dd2b0135b317C4C81332128880042F29,
        0x852304D1Cf6FA884538aDcE8eCde407e92a29eF7,
        0x0FdAa57856b8C72CF5bd70bAF383Ca07D02DadE1,
        0x5c623e9065bF15692bFBE70028eBAAe64b1FB056,
        0x35d9c39EB367b26977aB566E1405F17CE87c21b5,
        0x75b92Ca4e0B0fF3DaD36E6a3C12816f059Fa5826,
        0x2Af39413b9867F363316907b7a247a1A74b05498,
        0x58ce8CA80e01543854A07cd9E86Ce567272B82f8,
        0x1424704156c915905D67829C9BF331aA144985bb,
        0xD6e5BC8C4A290edc8Bf0ac43aba849886539daE6,
        0x44Db11aCD009266f8Eb6785E6AD81A82771e8bD9,
        0x2221Dd7ee891a35fbc207b35000064a69FC64f43,
        0x5ee60302b8d47c606C2dd1107936f0B2466f855f,
        0xA706d91a5deF67fDB82Fc79f7477E26061D72133,
        0xB922b2225B45BD7952BAA9Fa47c92038eaCd6143,
        0xa81dF00B0125B6F1341b0690Dc8d4Fa69ce7DC9A,
        0xFC37A4e2646CfcBf9Fe10165cAC369a1B886a619,
        0x6363A52310b6847EccFdB4494a416f3a0f27c543,
        0x9B11d5767F7C9aEe706F9B13Ca885E47087a5209,
        0x8B779a702714E503c558a3274E9C2C5D7a22BbD0,
        0x4928adF1D3E242544725eCCF67768A7E09f15A15,
        0x58Fc8A25ff10AD251E33784C9aEC17389952306e,
        0x9321f2C8BfCB8e170b3F9309b3a1907Fda4B0c47,
        0xe22039e378F3F9F6C56b83413f3aF0d025ed2368,
        0x5b0C1F1F40F73605ec4c77c47636876B63c67400,
        0x4B9c86d7C271dDC2ea06342317F52B1b037c7Da2,
        0x74229C516A4b63Df9De05a99eC127580fFae64F0,
        0xb845E9251047fAB15774ED49463a649fddAB7ff2,
        0x94B8d1c67F038FD52AE109e53983daB59D463218,
        0x12Df54D233740fca59AbD58C42d237fF11354fc3,
        0xD2A4d21A754d5FE8e517edE721F15f94799A9B2D,
        0x9344d150e92B7C63ed8DA289161b6bEc4D787272,
        0x9cDBd30D5e7c6EF84A2f65b55e7744B5613E77D1,
        0x17efc8883aCDC837C5b5535Af9B6f97DaD281feF,
        0x3CC10475a64a906E5dA68c341e74A7380b745dC4,
        0x0C4dAd9F513DBB46DEc96Dc82Da012297873E0a2,
        0x7A155C1FfE2ea038b3b5687496bFbC94FdBfC6C9,
        0x70b23097346948c0B50585c6F32dCECeab6cf25e,
        0x03C82080e322D42CB4cc38Bd5E8efEA154957c7e,
        0xc39342E189AfD0bE8A7507cbea11879d8b8fabb0,
        0xD03270f2B2F6Eec2Cc2d94b59d8B560f8990220E,
        0x966a6861B34AC3F4539915F8BEcCF1C4B2Eb5cDE,
        0xd8eBd953504537d9193512a8CA7b4723183E4695,
        0x8FF87eF95DD3c69857dCcAd49597739d20662f4C,
        0xc38551eDC20eA03A26Cdef9A0B96f4716c763352,
        0x8F4f29D63e7cC5788FF924773b7f1D590CD4F6cb,
        0x6D4267CBD241eDdc0ffbB857D70F5c47a908980f,
        0xC4E21b31b9BbA3030C03cA558Ac683ee6Aa2885C,
        0xe155341AD556a97C0AeDDE1E39c5bAc83170C2e8,
        0x7F9D03253951a8f4E4cb4c3e3355Abf42ceA4A74,
        0xE337fc0B894238F5E198D8D07503ce27BfA310Ce,
        0x2f9Ea193a21B446F62264A8F0c354C293447507F,
        0xB87B4944a9DecdC72D7aCD941FA024607f8953c8,
        0xa5F3dC95B52C91b0CC81cadd0b13d9b678dAF053,
        0x5c45B73fEb524B3F41fafB21061b12212B62DAF9,
        0xdC172eA9E5952C735569234af96343dC69BeA16d,
        0x2Be4D1EDe9f450f861340Cac6dA0550fF839DD10,
        0x69b83c7e16d78227B27067E6495218e6dB4c8e57,
        0xcFdCA673b940F3740901052CC96Fc38D7E5Ac22F,
        0x243bC3d1cc01a899aC1c88d05b2AA83d100d4Bb5,
        0x021d88281Aa20f381500B1a3A733950B40c48E3D,
        0xde76633D16dbe4F55D7d4f56561399742C5Ec622,
        0xf2c923BE749FBb64E8f102f15d1E12485F53903B,
        0xcbf1C1562E6Fb4A6221Afb7DB747F660698fD4DC,
        0xc3833b86D93F678F65C7740De3D8fA9EbA43d5e0,
        0x009B68fA29784dBCE543D83444D7A0DE955f2C28,
        0x3b883283504A01304b1095fB66eaB01B2776Be90,
        0x31674E819D54f91bBbE0A7e20360E62F2dfdA718,
        0x5Cc7D873e012998827D1FCA8C40d04d5b76Dd37f,
        0x88cD790eef9FaEA0785ba013F0B495B50e3bdf98,
        0xAd7Fc292dD43C61Da99F79A204840237D1D6c05F,
        0x8007539CE2150FE53BDe0347f3Ff65a176B94FE9,
        0x46AAA75641894F0854450F7488BE35fc185757cD,
        0xC067c5585990784E8e8Ae66080eC5e14602E57C1,
        0xA0B0b35d516c9C527728cEFdF05b7f248DeaBF05,
        0xc494c0256Dc1AaBD677eb1422C21eEd4A11fcaB9,
        0x464180CCACEF1F3503F327831822E37B7CD7d458,
        0x505bF56a4E815E4C5bcfA8a4cF7626B391AaAf33,
        0x12F961C476Eae4279847c39f329E74a327472669,
        0x0202D8aE3D714dB20EBa1380f2e90EfeFda4422F,
        0x8f81C4553b4b55F323496ED2e35F95a6635941c9,
        0x56dA315910A5001941C53dc0766b0c274A9e80DD,
        0x59BD64c9b741d1d62D29434cF7BAe1298324a829,
        0x3bBb709447d1DAC8726CfEba381143CD1ca887A5,
        0xddda5168d6d7D696Be7393df51f2D4d4C8640890,
        0xe5b46eA6A8e364A31CF67cE32DdDB94C2B603D52,
        0x3fc8Dacec4E0ED8ee24E0F7a5fdA8E095AC3A099,
        0x1dec07A061848117Cf9dC419f6cb61973a702FE5,
        0x0682b305bE03f2Ec9Dd4AAf717E719Ba340bA15c,
        0x7ac0a0981998623A2c547c88F2e1276e926317FD,
        0xb89737214a90352eD78Cf6adB18a4562258d10e8,
        0xDf4F7dB9f101bc73A611526C68c56Aaa8Ef65292,
        0x13Bb3Ec8f66205c92E18714a42649C21A22f896e,
        0x767dD5efe2F7893814B611304FC78Be3bC3b776C,
        0x771999982FC377611Aba04b212DBCCe76F8a3CBa,
        0xC34fE5Cc733EfE27fC07D84A778E82f855ed3C44,
        0x9CCd386c374dB0e24c2D2e099E05da246cC53a1A,
        0x8AB702EDF82c2fcD4D48f936bC30ee201C44d39E,
        0xE7092677D0C426a0c305BBAB4812821dcD26a8C8,
        0x80AaD0ce4bea116f0a580EDC319a9b1724F53c35,
        0xa8b1ba907A153A4bc852cdA9B0D0352076dF23c3,
        0x9adF25D0f237d145bD5947837F56E45aCf979F65,
        0x01BC74a11ec18546989D63568cecB55FD05808dA,
        0x00B85694144CEcAFdc5E88A499697b71c44E20f3,
        0x7973020879B7F1a194b525fc915ae7687b16BE7b,
        0x1768a88f40b28752B5aB6D3EADa9F4117edc181e,
        0x24dbCA201bb3432B4564F4bae8A4Fd53a8E36E31,
        0x41C77D0F00E6be497A828B29eE77a3fBc917F4e9,
        0xbdaA5762414f1E23e7eF3B44984b4241A6229b2B,
        0xC5b65C135e92ff33b1D1E085C428732c22214829,
        0x5E16D8C5aBA1Dfd88805F627b74Aa69d62070088,
        0xe753DaA78aEBcB020959fF98f3c3FD3efEF46650,
        0xB20b7B64dcEd3A62E120fF1141805EfCf8894BA6,
        0xdc55e7810aCC05cd4DE61e2E4e2Cbdc541eB7304,
        0x2B332B59553c2f4cf7B0040Da6CCEBe2c091fe37,
        0xa3003B330EeC36d0A39e382fb0924e803ff666B9,
        0xABE5cdAdF017D4F598e70a0cc576fBe8ab140083,
        0x61D53E946E370a89Dc8F3E6939cC6c1F7291eF20,
        0xFca48084E40A119EE1E078676e261ff13F99DD14,
        0x330F5d9fDF3A5Df8cf6652475dbFA9Ffab796D24,
        0x97cA425b1cA00bDc476891302DFAc1A43bDAfdFd,
        0x3C984Fb2f91fd078a089AD98A798142e1fE05897,
        0xb6dB87eF718631B3B797520a5880aBFFEA8fc073,
        0x9197891057ca73abdD4B33D3FefC5e3E92f7E756,
        0x05ce29c8449B68d9B2FEd3A4DcB141381E5cc3bd,
        0x790eEB1701fFfED691E1f937E86A3BaDD8395075,
        0xf0E7f82F707742340c74387799f23f8B88AbE502,
        0x24a1954c17274B3C3505f50f0f251e3b4079Eb07,
        0xAc28494893968b2eaB6CE32E0F362F3a0542Ebc8,
        0x8E801D966b11B19D19e4DE68C4C7D0D543cDc81f,
        0x1bbba81B0B8df7Bdb4567d60090C952143cC98F7,
        0xb2c81C05db84631aFEA31BC3a3361309281361D0,
        0xFB485c66f7a3492251B9Fd0c5c625aD97C723561,
        0x53b7a2152503ae2D27D1fD1A7d560191b4bc3Cc1,
        0x8E2dc4cB7a2CB7bb338324b45f5643dD7230b709,
        0x491cE2EFB8efd7B5a62a3721A389aC0574F18554,
        0xf00B329e3E61af7be7a5e7a2B2DE1B0d70Ce2139,
        0x50c50917c6c956dD7a1f07E02Af2802145bE1A1A,
        0x9fc4590351a6F799bc5B627e72FAb9bF9C482C83,
        0x84bB811Da91526e7eCA44BC6C91942DcF5c0e6c2,
        0x34CE4eb9CEf41E3Fa8E9cBe882A0f1feEd9092F0,
        0xeAbDc1F755A18721E399918060b130b4864cF438,
        0x3941c4d455C4A4ED6A177469BD2CBa00a875D713,
        0xCc4ca8018fe8063B9B8a5317269E3D5A0c9ceB12,
        0xFBa89B41e47809394Fdbe06D19faE7dc71240a3F,
        0x47a3c52b1448f3748f6Bf4343BAf6A39a671a5f1,
        0x03152A74AD496f7686D279C58DBCb44C7365D8F9,
        0xD3FF9beB4c84955d4e3a8a49704a2dDFa2d021cD,
        0xFE3Cb9B52f0f2508701c5DDdD1ec8322c39f7861,
        0x68e84fA9b2aB25C79eb8A6043E2D42FA26aa4d2f,
        0x3702064C59a6c5f74E1097E096c4D49b646Ded2E,
        0x488a84285B2E9452c80F35D347042c8324A24eBA,
        0x95A17f80DF6816Bfe4365652114c940394F1C255,
        0xE7eA58f486D7E9F9b6CFfd90e9B537CE7a57E991,
        0x0c93a82b1905b686d2bE729588B1205aF5eBd108,
        0xE72D54322e2dC944FF8a1f2bcda49f75B1e3128B,
        0x5255AA80baE0449Bc97ce29e080dD8359eD11BB9,
        0xE343eeEF6Ae4E94CaC92334922b3Fa069E3c9463,
        0x7c231e90c39D8E1B032044F38B13004A77400855,
        0xf7e308b1e0290aF37a57aa97a7FC75BC99165000,
        0x29819a1Fd47aeEcA1337df62aD28F806d431e8a8,
        0x6fd2B5a4Db03159C021FfE2d7bb7ffbB911912BF,
        0x28214943AE9Ae04Bc118a49996c3aA47970fB1b1,
        0x6e9af1F76d7b09849Ac92a0ef7f63FEFa2995c6A,
        0xE00FCBF90bB2A14101b4cD1554B16fF7C652f4fd,
        0x2d4e45945746780ff46A18255EcADac92c374B79,
        0x940A991F280F43f354209804e7A914EB8bEAf86f,
        0xB882cfbbCA3198B00afB805E1c78EdFadeb455c1,
        0x37104d59E899c558Ea60518Af3F43E46bA040e07,
        0xf8a39107886A98704932EFF4d604218D0c404ba9,
        0x9a81631c1Fc60c9DB895B7a8fF2BF481576883C3,
        0x3Df6139DAC6D8713595F0bEe243FFeda557eBAa7,
        0x9684E8eDE936f99AE180627229Dd2b240877D203,
        0x36F8fe2055BB4D13F335890C2a27426B5a7E0650,
        0x04AE3803751097103680f928D8F80B33ad5E1c65,
        0x02aC25b565c053bc1E7Aa2A1499622512Af375F1,
        0xC0CF49ecfb4959214Ce512BeD6f76dfFead53835,
        0x10629761cA412c70D4126cDe1fa74208cC2D43bE,
        0x75D9a1c8cD935cBDE11C90a7981a8FE91164214b,
        0xB4480Aa75a1BA20cA832dC45281a29422E5aA02D,
        0x92DAE80250bd7A90dAb5DC54900599b12684F060,
        0x3BFE45659593D1591b2aa12a513359780E9f2bD8,
        0xDcB4E36d6a793E27fbCB82d28E65f805f46AaB37,
        0x8668AfEE27cCF48C5dE3A9e1C73F15F1DF31511D,
        0x2733AC6c20720728d48A4f0df99Ec89067EAbEfB,
        0x2d93f9BFF32B9E9475A45A697E62e0d7Ee236361,
        0x93bB55C87AE5dDFcfecbfAdd8F567192a3580CA1,
        0xF5fb7348ab5a4B02174317179c6F23A5832Ec409,
        0xBe48D272D220215a344cB8EFE9bD152E9136c9FC,
        0x78a22A246f9DC046b9083CcE92E9E4bBA10F1469,
        0xC57a74712c07B2da2015B9C9DdaDDdDEFdB72123,
        0xd5A2D543ce37Edf5456F0E7E2b727461a3E7bFAB,
        0xbD64D5D0236733f5b1261C3fc13aBba9D46D4F5C,
        0x3F8288611fD9C29b7b8843C18A4c5B7379776A6A,
        0x27fD36DD54457F26072491B44b209bC0dEd74495,
        0xf7b32C6CAE399443caAc7CC1e73FbCfC05fF62CB,
        0xb72AA91aD1Dd4bc3929aE3008664d9371F79f158,
        0x62aB9E8d0aeFb736179DF59aD14B67c58747a427,
        0xf15Bd78ed99f862a57D52Ae2D94FaE06FAFe6605,
        0x1037F3910fADB3c39E6E5219D2b844e3457e9C5f,
        0x496d72845d3a1fdf4164ce5DEc54bAf8882966e2,
        0x807997702E462Ba6a70E3219b0219E24a76CC4DD,
        0x717dEc8795C0E2E277e8B165592343347B5a848F,
        0x2BEbE84f4c25Af157A4697CD059316c47C724843,
        0x7D1Ba68c2C2efE1b462D92e4F00Be38B1894198F,
        0xd28dBAf3Fa4ef4d5f3CCb9b873B7f278364A7d5f,
        0x8523a8A4191b307783f86AbC9f6B7164931a4c69,
        0xC9083876093e7A2133D13B6f8C7297f110Dad3E7,
        0x352F63A02033ebb8F42F0893Dc2baAF739eA3dca,
        0x139114D72D8BF23970351B85498d1Bf5fA89590C,
        0xE730271914976a11dA1b6635AD4f33CBbC7E463A,
        0x3E0c0894D864b0a394C1f2d36DC57F5caAb15037,
        0x5b798beFf16A7D24c43436f66CEf72007394De09
    ];

    struct Plan {
        uint period;
        uint percent;
        uint specialPercent;
        bool active;
    }
    Plan[] public plans;

    struct Deposit {
        address owner;
        address referral;
        uint amount;
        uint proceeds;
        uint referralProceeds;
        uint created;
        uint closed;
        bool special;
    }
    Deposit[] public deposits;

    event PlanEvent(
        uint indexed planId,
        uint indexed period,
        uint percent,
        uint specialPercent,
        bool active
    );
    event DepositEvent(
        uint indexed depositId,
        address indexed owner,
        address indexed referral,
        uint amount,
        uint proceeds,
        uint referralProceeds,
        uint created,
        uint closed,
        bool special
    );

    constructor(address _hashTokenAddress) {
        hashTokenAddress = _hashTokenAddress;
        plans.push(Plan(0, 10, 15, true));
        plans.push(Plan(10 * 60, 15, 25, true));
        plans.push(Plan(20 * 60, 25, 50, true));
        plans.push(Plan(30 * 60, 50, 100, true));
        plans.push(Plan(40 * 60, 100, 200, true));
    }

    function updateProceedsLimit(uint _proceedsLimit) external onlyOwner {
        require(_proceedsLimit != proceedsLimit, "You must specify a different value");
        require(_proceedsLimit >= getMaxTotalProceeds(), "The value is too small");
        if (_proceedsLimit > proceedsLimit) {
            TransferHelper.safeTransferFrom(hashTokenAddress, msg.sender, address(this), _proceedsLimit - proceedsLimit);
        } else {
            TransferHelper.safeTransfer(hashTokenAddress, msg.sender, proceedsLimit - _proceedsLimit);
        }
        proceedsLimit = _proceedsLimit;
    }

    function updateMaxPeriod(uint _maxPeriod) external onlyOwner {
        maxPeriod = _maxPeriod;
    }

    function addPlan(uint _period, uint _percent, uint _specialPercent) external onlyOwner {
        for (uint i = 0; i < plans.length; i++) {
            if (plans[i].period == _period) {
                _updatePlan(i, _percent, _specialPercent);
                return;
            }
        }
        uint planId = plans.length;
        plans.push(Plan(_period, _percent, _specialPercent, true));
        require(proceedsLimit >= getMaxTotalProceeds(), "Unable to add the plan: too high percents");
        emit PlanEvent(planId, _period, _percent, _specialPercent, true);
    }

    function updatePlan(uint _planId, uint _percent, uint _specialPercent) external onlyOwner {
        _checkPlan(_planId);
        _updatePlan(_planId, _percent, _specialPercent);
        require(proceedsLimit >= getMaxTotalProceeds(), "Unable to update the plan: too high percents");
    }

    function activatePlan(uint _planId) external onlyOwner {
        _checkPlan(_planId);
        require(plans[_planId].active == false, "The plan is already active");
        plans[_planId].active = true;
        require(proceedsLimit >= getMaxTotalProceeds(), "Unable to update the plan: too high percents");
        emit PlanEvent(_planId, plans[_planId].period, plans[_planId].percent, plans[_planId].specialPercent, true);
    }

    function deactivatePlan(uint _planId) external onlyOwner {
        _checkPlan(_planId);
        require(plans[_planId].active == true, "The plan is already deactivated");
        plans[_planId].active = false;
        emit PlanEvent(_planId, plans[_planId].period, plans[_planId].percent, plans[_planId].specialPercent, false);
    }

    function finishStaking() external onlyOwner {
        require(stakingFinished == false, "The staking is already finished");
        stakingFinished = true;
    }

    function restartStaking() external onlyOwner {
        require(stakingFinished == true, "The staking is already active");
        stakingFinished = false;
    }

    function addEarlyInvestor(address _address) external onlyOwner {
        require(_address != address(0), "Incorrect address");
        for (uint i =0; i < earlyInvestors.length; i++) {
            if (earlyInvestors[i] == _address) {
                revert("The address is already in the list");
            }
        }
        earlyInvestors.push(_address);
    }

    function removeEarlyInvestor(address _address) external onlyOwner {
        require(_address != address(0), "Incorrect address");
        for (uint i =0; i < earlyInvestors.length; i++) {
            if (earlyInvestors[i] == _address) {
                earlyInvestors[i] = address(0);
                return;
            }
        }
        revert("The address is not in the list");
    }

    function makeDeposit(uint _amount, address _referral) external {
        require(stakingFinished == false, "The staking is finished");
        bool special = isEarlyInvestor(msg.sender);
        address referral = address(0);
        if (_referral != address(0) && _referral != msg.sender) {
            for (uint i = 0; i < deposits.length; i++) {
                if (deposits[i].owner == _referral && deposits[i].closed == 0) {
                    referral = _referral;
                    break;
                }
            }
        }
        uint depositId = deposits.length;
        uint maxProceeds = _amount * _getMaxPercent(special) * maxPeriod / (100 * 365 * 24 * 60 * 60);
        if (referral != address(0)) {
            maxProceeds += maxProceeds * referralPercent / 100;
        }
        require(getMaxTotalProceeds() + maxProceeds <= proceedsLimit, "Unable to make a deposit, the amount is too large");
        TransferHelper.safeTransferFrom(hashTokenAddress, msg.sender, address(this), _amount);
        uint currentTime = block.timestamp;
        deposits.push(Deposit(msg.sender, referral, _amount, 0, 0, currentTime, 0, special));
        emit DepositEvent(depositId, msg.sender, referral, _amount, 0, 0, currentTime, 0, special);
    }

    function closeDeposit(uint _depositId) external {
        require(deposits.length > _depositId, "Incorrect deposit ID specified");
        require(deposits[_depositId].owner == msg.sender, "Forbidden");
        require(deposits[_depositId].closed == 0, "Already withdrawn");
        uint currentTime = block.timestamp;
        uint proceeds = _calculateProceeds(deposits[_depositId].amount, block.timestamp - deposits[_depositId].created, deposits[_depositId].special);
        deposits[_depositId].closed = currentTime;
        deposits[_depositId].proceeds = proceeds;
        TransferHelper.safeTransfer(hashTokenAddress, msg.sender, deposits[_depositId].amount + proceeds);
        uint referralProceeds = 0;
        if (deposits[_depositId].referral != address(0)) {
            referralProceeds = proceeds * referralPercent / 100;
            deposits[_depositId].referralProceeds = referralProceeds;
            TransferHelper.safeTransfer(hashTokenAddress, deposits[_depositId].referral, referralProceeds);
        }
        emit DepositEvent(
            _depositId,
            msg.sender,
            deposits[_depositId].referral,
            deposits[_depositId].amount,
            proceeds,
            referralProceeds,
            deposits[_depositId].created,
            currentTime,
            deposits[_depositId].special
        );
    }

    function makeDepositCheck(address _address, uint _amount, address _referral) external view returns(bool success, uint maxAmount) {
        success = false;
        if (stakingFinished == true) {
            maxAmount = 0;
        } else {
            bool special = isEarlyInvestor(_address);
            address referral = address(0);
            if (_referral != address(0) && _referral != msg.sender) {
                for (uint i = 0; i < deposits.length; i++) {
                    if (deposits[i].owner == _referral && deposits[i].closed == 0) {
                        referral = _referral;
                        break;
                    }
                }
            }
            uint maxPercent = _getMaxPercent(special);
            uint maxReferralPercent = 0;
            uint maxProceeds = _amount * maxPercent * maxPeriod / (100 * 365 * 24 * 60 * 60);
            if (referral != address(0)) {
                maxReferralPercent = referralPercent;
                maxProceeds += maxProceeds * referralPercent / 100;
            }
            if (maxProceeds <= proceedsLimit - getMaxTotalProceeds()) {
                success = true;
            }
            maxAmount = proceedsLimit * 100 * 100 * 365 * 24 * 60 * 60 / (maxPercent * (100 + maxReferralPercent) * maxPeriod);
        }
    }

    function calculateProceeds(uint _amount, address _address, uint _period) external view returns (uint proceeds) {
        proceeds = _calculateProceeds(_amount, _period, isEarlyInvestor(_address));
    }

    function calculateDepositProceeds(uint _depositId) external view returns (uint proceeds) {
        require(deposits.length > _depositId, "Incorrect deposit ID specified");
        require(deposits[_depositId].closed == 0, "The deposit is closed");
        proceeds = _calculateProceeds(deposits[_depositId].amount, block.timestamp - deposits[_depositId].created, deposits[_depositId].special);
    }

    function getMaxTotalProceeds() public view returns (uint proceeds) {
        proceeds = 0;
        uint currentProceeds;
        for (uint i = 0; i < deposits.length; i++) {
            if (deposits[i].closed > 0) {
                currentProceeds = deposits[i].proceeds + deposits[i].referralProceeds;
            } else {
                currentProceeds = deposits[i].amount * _getMaxPercent(deposits[i].special) * maxPeriod / (100 * 365 * 24 * 60 * 60);
                if (deposits[i].referral != address(0)) {
                    currentProceeds = currentProceeds * (100 + referralPercent) / 100;
                }
            }
            proceeds += currentProceeds;
        }
    }

    function isEarlyInvestor(address _address) public view returns (bool) {
        for (uint i = 0; i < earlyInvestors.length; i++) {
            if (earlyInvestors[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function _getMaxPercent(bool _special) internal view returns (uint percent) {
        percent = 0;
        for (uint i = 0; i < plans.length; i++) {
            if (plans[i].active == false || plans[i].period > maxPeriod) {
                continue;
            }
            if (!_special && plans[i].percent > percent) {
                percent = plans[i].percent;
            } else if (_special && plans[i].specialPercent > percent) {
                percent = plans[i].specialPercent;
            }
        }
    }

    function _calculateProceeds(uint _amount, uint _period, bool _special) internal view returns (uint proceeds) {
        if (_period > maxPeriod) {
            _period = maxPeriod;
        }
        uint percent = 0;
        uint currentPlanPeriod = 0;
        for (uint i = 0; i < plans.length; i++) {
            if (plans[i].active == true && _period >= plans[i].period && plans[i].period >= currentPlanPeriod) {
                currentPlanPeriod = plans[i].period;
                percent = _special ? plans[i].specialPercent : plans[i].percent;
            }
        }
        proceeds = _amount * percent * _period / (100 * 365 * 24 * 60 * 60);
    }

    function _checkPlan(uint _planId) internal view {
        require(plans.length > _planId, "Incorrect plan ID specified");
    }

    function _updatePlan(uint _planId, uint _percent, uint _specialPercent) internal {
        require(plans[_planId].percent != _percent, "You must specify a different value");
        plans[_planId].percent = _percent;
        plans[_planId].specialPercent = _specialPercent;
        plans[_planId].active = true;
        emit PlanEvent(_planId, plans[_planId].period, _percent, _specialPercent, true);
    }
}