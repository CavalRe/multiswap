
import { FC } from "react";
import { useMoralis } from "react-moralis";
import {
    Card,
    Group,
    NumberInput,
    Text
} from "@mantine/core";

import type { TokenComponentProps } from "../TokenSelect";

const PayComponent: FC<TokenComponentProps> = (props: TokenComponentProps) => {
    const { token, swapState, getQuote } = props;
    const { poolToken, assetTokens } = swapState;
    const { isAuthenticated } = useMoralis();

    const handleAmountChange = (amount: number) => {
        if (token.address == poolToken.address) {
            poolToken.amount = amount;
        } else {
            assetTokens[token.address].amount = amount;
        }
        getQuote({ poolToken, assetTokens });
    };

    return (
        <Card radius="md" mt="xs">
            <input type="hidden" name="address" />
            <input type="hidden" name="payToken" value={JSON.stringify(token)} />
            <NumberInput
                precision={2}
                size="lg"
                icon={<Text size="md">{token.symbol}</Text>}
                hideControls
                value={token.amount}
                onChange={(a: number) => handleAmountChange(a)}
                min={0}
                error={isAuthenticated && token.amount > token.allowance ? "Insufficient allowance ("+token.symbol+" "+token.allowance+")" : false}
            />
            <Group mt="xs" position="left">
                <Text>Pool Balance:</Text>
                <Text>{token.contractBalance.toLocaleString()}</Text>
                <Text>{token.symbol}</Text>
            </Group>
            <Group mt="xs" position="left">
                <Text>Account Balance:</Text>
                <Text>{token.accountBalance.toLocaleString()}</Text>
                <Text>{token.symbol}</Text>
            </Group>
        </Card>
    );
};

export default PayComponent;
