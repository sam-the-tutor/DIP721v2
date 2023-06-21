import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Types "Types";
import List "mo:base/List";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

actor class DIP721v2(_custodian : Principal, _name : Text, _symbol : Text, _logo : Text) {

  func natHash(n : Nat) : Hash.Hash {
    Text.hash(Nat.toText(n));
  };
  var totaltransactions : Nat = 0;
  stable var collectionName : Text = _name;
  stable var collectionLogo : Text = _logo;
  stable var collectionSymbol : Text = _symbol;
  stable var collectionCustodians = List.make<Principal>(_custodian);

  let nullAddress = Principal.fromText("aaaaa-aa");

  stable var initMetadata : Types.Metadata = {
    logo = ?collectionLogo;
    name = ?collectionName;
    created_at = 989; //pending time conversion here
    upgraded_at = 0;
    custodians = [_custodian];
    symbol = ?collectionSymbol;
  };

  let tokens = HashMap.HashMap<Nat, Types.TokenMetadata>(0, Nat.equal, natHash);
  let owners = HashMap.HashMap<Principal, List.List<Nat>>(0, Principal.equal, Principal.hash);
  let operators = HashMap.HashMap<Principal, List.List<Nat>>(0, Principal.equal, Principal.hash);

  public query func isCustodian(p : Principal) : async Bool {
    let result = List.find<Principal>(collectionCustodians, func x { x == p });
    switch (result) {
      case (null) { return false };
      case (?value) { return true };
    };
  };

  public query func logo() : async Text {
    return collectionLogo;
  };

  public query func name() : async Text {
    return collectionName;
  };

  public query func symbol() : async Text {
    return collectionSymbol;
  };

  public shared ({ caller }) func setName(newName : Text) : async () {
    if (await isCustodian(caller)) {
      collectionName := newName;
    };
  };

  public shared ({ caller }) func setLogo(newLogo : Text) : async () {
    if (await isCustodian(caller)) {
      collectionName := newLogo;
    };
  };

  public shared ({ caller }) func setSymbol(newSymbol : Text) : async () {
    if (await isCustodian(caller)) {
      collectionName := newSymbol;
    };
  };

  public query func metadata() : async Types.Metadata {
    return initMetadata;
  };

  public query func custodians() : async [Principal] {
    return List.toArray<Principal>(collectionCustodians);
  };

  public shared ({ caller }) func setCustodians(_custodians : [Principal]) : async () {
    if (await isCustodian(caller)) {
      for (_custodians in _custodians.vals()) {
        ignore List.push<Principal>(_custodian, collectionCustodians);
      };
    };
  };

  public query func stats() : async Types.Stats {
    return ({
      cycles = Cycles.balance();
      total_transactions = totaltransactions;
      total_unique_holders = owners.size();
      total_supply = tokens.size();
    });
  };

  public query func totalUniqueHolders() : async Nat {
    return owners.size();
  };

  public query func totalSupply() : async Nat {
    return tokens.size();
  };

  public query func cycles() : async Nat {
    return Cycles.balance();
  };

  public query func totalTransactions() : async Nat {
    return totaltransactions;
  };

  public query func ownerOf(id : Nat) : async Result.Result<Principal, Types.NftError> {
    let result = tokens.get(id);

    switch (result) {
      case (null) { #err(#TokenNotFound) };
      case (?value) {
        switch (value.owner) {
          case (null) { return #err(#OwnerNotFound) };
          case (?owner) { return #ok(owner) };
        };
      };
    };

  };

  public query func balanceOf(p : Principal) : async Result.Result<Nat, Types.NftError> {
    let result = owners.get(p);
    switch (result) {
      case (null) { return #err(#OwnerNotFound) };
      case (?tokens) {

        return #ok(List.size<Nat>(tokens));
      };
    };
  };

  public query func tokenMetadata(id : Nat) : async Result.Result<Types.TokenMetadata, Types.NftError> {
    let result = tokens.get(id);
    switch (result) {
      case (null) { return #err(#TokenNotFound) };
      case (?token) { return #ok(token) };
    };
  };

  public query func ownerTokenIdentifiers(p : Principal) : async Result.Result<[Nat], Types.NftError> {
    let result = owners.get(p);
    switch (result) {
      case (null) { return #err(#OwnerNotFound) };
      case (?tokenList) {
        return #ok(List.toArray<Nat>(tokenList));
      };
    };
  };

  public query func ownerTokenMetadata(p : Principal) : async Result.Result<[Types.TokenMetadata], Types.NftError> {
    let result = owners.get(p);

    switch (result) {
      case (null) { return #err(#OwnerNotFound) };
      case (?tokenList) {

        let metaDaTa = Buffer.Buffer<Types.TokenMetadata>(0);
        for (tokenId in List.toArray<Nat>(tokenList).vals()) {
          let res = tokens.get(tokenId);
          switch (res) {
            case (null) {};
            case (?value) {
              metaDaTa.add(value);
            };
          };
        };

        return #ok(Buffer.toArray<Types.TokenMetadata>(metaDaTa));
      };
    };

  };

  public query func operatorOf(id : Nat) : async Result.Result<?Principal, Types.NftError> {
    let result = tokens.get(id);
    switch (result) {
      case (null) { return #err(#TokenNotFound) };
      case (?token) {
        switch (token.operator) {
          case (null) { return #err(#OperatorNotFound) };
          case (?operator) { return #ok(?operator) };
        };

      };
    };
  };

  public query func operatorTokenIdentifiers(p : Principal) : async Result.Result<[Nat], Types.NftError> {
    let results = operators.get(p);
    switch (results) {
      case (null) { return #err(#OperatorNotFound) };
      case (?tokenList) { return #ok(List.toArray<Nat>(tokenList)) };
    };
  };

  public query func operatorTokenMetadata(p : Principal) : async Result.Result<[Types.TokenMetadata], Types.NftError> {
    let results = operators.get(p);

    switch (results) {
      case (null) { #err(#OperatorNotFound) };
      case (?tokenList) {
        let newList = Buffer.Buffer<Types.TokenMetadata>(0);

        for (tokenId in List.toArray<Nat>(tokenList).vals()) {
          let res = tokens.get(tokenId);
          switch (res) {
            case (null) {};
            case (?tokenData) {
              newList.add(tokenData);
            };
          };
        };
        return #ok(Buffer.toArray<Types.TokenMetadata>(newList));
      };
    };

  };

  public query func supportedInterface() : async [Types.SupportedInterface] {
    return [#Burn, #Mint, #Approval, #TransactionHistory];
  };

  public shared ({ caller }) func burn(id : Nat) : async Result.Result<Nat, Types.NftError> {
    switch (tokens.get(id)) {
      case (null) { return #err(#TokenNotFound) };
      case (?token) {
        switch (token.owner) {
          case (null) { return #err(#OwnerNotFound) };
          case (?value) {

            tokens.put(
              id,
              {
                transferred_at = token.transferred_at;
                transferred_by = token.transferred_by;
                owner = ?nullAddress;
                operator = token.operator;
                approved_at = token.approved_at;
                approved_by = token.approved_by;
                properties = token.properties;
                is_burned = token.is_burned;
                token_identifier = token.token_identifier;
                burned_at = token.burned_at;
                burned_by = token.burned_by;
                minted_at = token.minted_at;
                minted_by = token.minted_by;
              },
            );
            //should return id to use in transactions
            return #ok(id);
          };
        };

      };
    };

  };

  public shared ({ caller }) func transfer(to : Principal, id : Nat) : async Result.Result<Nat, Types.NftError> {

    switch (tokens.get(id)) {
      case (null) { return #err(#TokenNotFound) };
      case (?token) {
        switch (token.owner) {
          case (null) { return #err(#OwnerNotFound) };
          case (?owner) {
            if (not (owner == caller)) {
              return #err(#UnauthorizedOwner);
            };
            tokens.put(
              id,
              {
                transferred_at = token.transferred_at;
                transferred_by = token.transferred_by;
                owner = ?to;
                operator = token.operator;
                approved_at = token.approved_at;
                approved_by = token.approved_by;
                properties = token.properties;
                is_burned = token.is_burned;
                token_identifier = token.token_identifier;
                burned_at = token.burned_at;
                burned_by = token.burned_by;
                minted_at = token.minted_at;
                minted_by = token.minted_by;
              },
            );
            //should return id to use in transactions
            return #ok(id);
          };
        };
      };
    };
  };

  public shared ({ caller }) func mint(to : Principal, id : Nat, properties : [(Text, Types.GenericValue)]) : async Result.Result<Nat, Types.NftError> {
    if (not (await isCustodian(caller))) {
      return #err(#UnauthorizedOperator);
    };

    let newNFT : Types.TokenMetadata = {
      transferred_at = null;
      transferred_by = null;
      owner = ?to;
      operator = null;
      approved_at = null;
      approved_by = null;
      properties = properties;
      is_burned = false;
      token_identifier = id;
      burned_at = null;
      burned_by = null;
      minted_at = 1000;
      minted_by = caller;
    };

    tokens.put(id, newNFT);
    switch (owners.get(to)) {
      case (null) {
        let newList = List.make<Nat>(id);
        owners.put(to, newList);
        return #ok(id);
      };
      case (?tokenList) {
        switch (tokenList) {
          case (null) {
            let newList = List.make<Nat>(id);
            owners.put(to, newList);
            return #ok(id);
          };
          case (?list) {
            let newList = List.append<Nat>(List.make<Nat>(id), ?list);
            owners.put(to, newList);
            return #ok(id);
          };
        };
      };
    };
  };
};
