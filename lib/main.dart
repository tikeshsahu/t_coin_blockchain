import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:t_coin/slider_widget.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Blockchain', home: const MyHomePage(title: 'T-Coin'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Client? httpClient;
  Web3Client? ethClient;
  bool data = false;
  int myAmount = 0;
  var myData;

  final myAddress = '0x7f861EA206fA7Ed846132bff017108f6A594d31e';

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        'https://rinkeby.infura.io/v3/7c08079541164e7fb1b91987b8f50ca6',
        httpClient!);
    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString('assets/abi.json');
    String contractAddress = '0xBd0DEca3CCAc09B0F07f6921b0c861882D6A463E';

    final contract = DeployedContract(ContractAbi.fromJson(abi, 'TCoin'),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(
      String functionName, List<dynamic> argument) async {
    final contract = await loadContract();

    final ethFunction = contract.function(functionName);
    final result = await ethClient!
        .call(contract: contract, function: ethFunction, params: argument);

    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    //EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query('getBalance', []);

    myData = result[0];
    data = true;
    setState(() {});
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        '3af6c131dab1ead8df0a8e1798500fab73b60d4e1e80c4a68464775aac453e21');

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient!.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract, function: ethFunction, parameters: args),
        fetchChainIdFromNetworkId:  true
        );
    return result;
  }

  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = submit('depositBalance', [bigAmount]);

    print('Deposited');
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = submit('withdrawBalance', [bigAmount]);

    print('Withdrew');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth, context.percentHeight * 30)
            .make(),
        VStack([
          (context.percentHeight * 10).heightBox,
          '\$T-Coin'.text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight * 5).heightBox,
          VxBox(
                  child: VStack([
            'Balance'.text.gray700.xl2.semiBold.makeCentered(),
            10.heightBox,
            data
                ? '\$ $myData'.text.bold.xl6.makeCentered().shimmer()
                : CircularProgressIndicator().centered()
          ]))
              .p16
              .white
              .size(context.screenWidth, context.percentHeight * 18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,
          SliderWidget(
            min: 0,
            max: 100,
            finalVal: (value) {
              myAmount = (value * 100).round();
              print(myAmount);
            },
          ).centered(),
          HStack(
            [
              FlatButton.icon(
                      onPressed: () => getBalance(myAddress),
                      color: Colors.amber,
                      shape: Vx.roundedSm,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      label: 'Refresh'.text.white.make())
                  .h(45),
              FlatButton.icon(
                      onPressed: () => sendCoin(),
                      color: Colors.green,
                      shape: Vx.roundedSm,
                      icon: Icon(
                        Icons.call_made,
                        color: Colors.white,
                      ),
                      label: 'Deposit'.text.white.make())
                  .h(45),
              FlatButton.icon(
                      onPressed: () => withdrawCoin(),
                      color: Colors.red,
                      shape: Vx.roundedSm,
                      icon: Icon(
                        Icons.call_received,
                        color: Colors.white,
                      ),
                      label: 'Withdraw'.text.white.make())
                  .h(45),
            ],
            alignment: MainAxisAlignment.spaceAround,
            axisSize: MainAxisSize.max,
          ).p16()
        ])
      ]),
    );
  }
}
