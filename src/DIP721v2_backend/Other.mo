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

    var tokenID : Nat = 0;

    stable var collectionName : Text = _name;
    stable var collectionLogo : Text = _logo;
    stable var collectionSymbol : Text = _symbol;
    stable var collectionCustodians = List.make<Principal>(_custodian);

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

    // public shared({caller}) func transfer(to: Principal, id : Nat) : async Result.Result<Nat,Types.NftError>{

    // };

    // public shared({caller}) func burn(id : Nat) : async Result.Result<Nat,Types.NftError>{

    // };

    // public shared({caller}) func mint(to : Principal, id : Nat) : async Result.Result<Nat,Types.NftError>{

    // };

    //optional interface
    public shared ({ caller }) func approve(p : Principal, id : Nat) : async Result.Result<Nat, Types.NftError> {
        let result = tokens.get(id);

        switch (result) {
            case (null) { #err(#TokenNotFound) };
            case (?token) {
                switch (token.owner) {
                    case (null) { #err(#OwnerNotFound) };
                    case (?owner) {
                        if (owner != caller) {
                            return #err(#UnauthorizedOwner);
                        };

                        let newToken : Types.TokenMetadata = {
                            transferred_at = token.transferred_at;
                            transferred_by = token.transferred_by;
                            owner = token.owner;
                            operator = ?p;
                            approved_at = null; //we need to convert time to nat64 and put it here
                            approved_by = ?caller;
                            properties = token.properties;
                            is_burned = token.is_burned;
                            token_identifier = token.token_identifier;
                            burned_at = token.burned_at;
                            burned_by = token.burned_by;
                            minted_at = token.minted_at;
                            minted_by = token.minted_by;

                        };

                        tokens.put(id, newToken);
                        //we have to setup the transaction part here
                        return #ok(id);
                    };
                };
            };
        };
    };

    public query func supportedInterface() : async [Types.SupportedInterface] {
        return [#Burn, #Mint, #Approval, #TransactionHistory];
    };

    public query func totalSupply() : async Nat {
        return tokens.size();
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

    public query func operatorTokenIdentifiers(p : Principal) : async Result.Result<[Nat], Types.NftError> {
        let results = operators.get(p);
        switch (results) {
            case (null) { return #err(#OperatorNotFound) };
            case (?tokenList) { return #ok(List.toArray<Nat>(tokenList)) };
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

    public query func totalUniqueHolders() : async Nat {
        return owners.size();
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

    public query func ownerTokenIdentifiers(p : Principal) : async Result.Result<[Nat], Types.NftError> {
        let result = owners.get(p);
        switch (result) {
            case (null) { return #err(#OwnerNotFound) };
            case (?tokenList) {
                return #ok(List.toArray<Nat>(tokenList));
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

    public query func balanceOf(p : Principal) : async Result.Result<Nat, Types.NftError> {
        let result = owners.get(p);
        switch (result) {
            case (null) { return #err(#OwnerNotFound) };
            case (?tokens) {

                return #ok(List.size<Nat>(tokens));
            };
        };
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

    // public query func stats() : async Types.Stats {

    // };

    public query func metadata() : async Types.Metadata {
        return initMetadata;
    };

    public query func cycles() : async Nat {
        return Cycles.balance();
    };

    public query func custodians() : async [Principal] {
        return List.toArray<Principal>(collectionCustodians);
    };

    public func setCustodians(_custodians : [Principal]) : async () {
        for (_custodians in _custodians.vals()) {
            ignore List.push<Principal>(_custodian, collectionCustodians);
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

    public func setName(newName : Text) : async () {
        collectionName := newName;
    };

    public func setLogo(newLogo : Text) : async () {
        collectionName := newLogo;
    };

    public func setSymbol(newSymbol : Text) : async () {
        collectionName := newSymbol;
    };

};
