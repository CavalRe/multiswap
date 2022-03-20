import { useEffect, useState } from "react";
import { useMoralis } from "react-moralis";
import { useNavigate } from "remix";
import {
    Button,
    Card,
    Container,
    Group,
    Modal,
    NativeSelect,
    SimpleGrid,
    Table,
    Text,
    Title
} from '@mantine/core';
import type { MantineSize } from "@mantine/core";

import type { Asset, Balance } from "~/moralis.server";

import { Swap } from "~/components/Dashboard";

type Dict<T> = {
    [key: string]: T
};

type Numeraire = {
    name: string,
    symbol: string,
    price: number
};

export { default as Header } from "~/components/Dashboard/Header";
export { default as NavBar } from "~/components/Dashboard/NavBar";
export { default as RequireAuth } from "~/components/Dashboard/RequireAuth";
export { default as Swap } from "~/components/Dashboard/Swap";

type DashboardProps = {
    contractAddress: string,
    address: string,
    poolTokens: number,
    assets: Asset[],
    balances: Balance[],
    pathname: string
};

const Dashboard = (props: DashboardProps) => {
    const {
        isInitialized,
        isAuthenticated,
        account,
        isWeb3Enabled,
        enableWeb3
    } = useMoralis();
    const { contractAddress, address, poolTokens, assets, balances, pathname } = props;

    const [opened, setOpened] = useState<boolean>(true);

    const navigate = useNavigate();

    useEffect(() => {
        if (isAuthenticated && !isWeb3Enabled) enableWeb3();

        const newPathname = isAuthenticated ? account ? `/dashboard/${account}` : pathname : "/dashboard";

        if (isInitialized && newPathname !== pathname) navigate(newPathname);
    }, [isInitialized, isAuthenticated, account])

    const assetMap: Dict<Asset> = {};
    assets?.forEach((a: Asset) => { assetMap[a.token_address] = a });

    const balanceMap: Dict<Balance> = {};
    balances?.forEach((b: Balance) => { balanceMap[b.token_address] = b });

    const poolToken = { name: "Pool Token", symbol: "P", price: 1 }
    const [numeraire, setNumeraire] = useState<Numeraire>(poolToken);

    const poolBalance = balanceMap[contractAddress] ? parseInt(balanceMap[contractAddress].balance) / 1e18 : 0;

    const price = (address: string) => {
        const asset: Asset = assetMap[address];
        return poolTokens * asset.weight / asset.reserve;
    };

    const balance = (address: string) => {
        const lowerAddress = address.toLowerCase();
        return balanceMap[lowerAddress] ? parseInt(balanceMap[lowerAddress].balance) / 1e18 : 0;
    };

    const numeraires = [poolToken, ...assets?.map((a: Asset) => ({ name: a.name, symbol: a.symbol, price: price(a.token_address) }))];
    const numeraireMap: Dict<Numeraire> = {};
    numeraires.forEach((n: Numeraire) => { numeraireMap[`${n.name} (${n.symbol})`] = n; });

    const handleNumeraire = (value: string) => {
        setNumeraire(numeraireMap[value]);
    };

    const numberOptions = {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    };

    const cellTextSize: MantineSize = "md";
    const headerTextSize: MantineSize = "lg";
    const subTextSize: MantineSize = "sm";
    const rows = assets?.map((a: Asset, i: number) => (
        <tr key={a.token_address}>
            {/* <td>{i + 1}</td> */}
            <td><span><Text size={cellTextSize} color="bold" component="span">{`${a.name}`}</Text><Text size="xs" color="dimmed" component="span">{` (${a.symbol})`}</Text></span></td>
            {address ? <td align="right"><Text size={cellTextSize}>{(balance(a.token_address) / numeraire.price).toLocaleString(undefined, numberOptions)}</Text></td> : null}
            <td align="right"><Text size={cellTextSize}>{(price(a.token_address) / numeraire.price).toLocaleString(undefined, numberOptions)}</Text></td>
            {/* <td align="right">{`${100 / (assets.length)}%`}</td> */}
            <td align="right"><Text size={cellTextSize}>{(a.reserve / numeraire.price).toLocaleString(undefined, numberOptions)}</Text></td>
            <td align="right"><Text size={cellTextSize}>{(10000 * a.fee).toLocaleString()}</Text></td>
            <td align="right"><Text size={cellTextSize}>{a.k.toLocaleString()}</Text></td>
        </tr>
    ));

    return (
        <Container>
            <Title>Liquidity Pool</Title>
            {isAuthenticated ?
                (<>
                    <Button onClick={() => setOpened(true)} mt="xl">Swap</Button>
                    <Modal
                        size="xl"
                        opened={opened}
                        onClose={() => setOpened(false)}
                        radius="lg"
                        title={<Title align="center" order={3}>Mulit-Asset Swap</Title>}
                    >
                        <Swap assets={assets} balances={balances}/>
                    </Modal>
                </>) : null}
            <Card withBorder p="xl" radius="md" mt="lg">
                <Title order={3}>Pool Tokens</Title>
                <SimpleGrid cols={address ? 4 : 3}>
                    {address ?
                        (<div>
                            <Text size="xl" mt="md">{(poolBalance / numeraire.price).toLocaleString() + " " + numeraire.symbol}</Text>
                            <Text size={subTextSize} color="dimmed">Balance</Text>
                        </div>) : null}
                    <div>
                        <Text size="xl" mt="md">{(poolTokens / numeraire.price).toLocaleString() + " " + numeraire.symbol}</Text>
                        <Text size={subTextSize} color="dimmed">TVL</Text>
                    </div>
                    <div>
                        <Text size="xl" mt="md">{poolTokens?.toLocaleString()}</Text>
                        <Text size={subTextSize} color="dimmed">Outstanding</Text>
                    </div>
                    <div>
                        <NativeSelect
                            mt="md"
                            value={`${numeraire.name} (${numeraire.symbol})`}
                            onChange={(event) => handleNumeraire(event.currentTarget.value)}
                            data={numeraires.map(n => `${n.name} (${n.symbol})`)}
                            description="Select numeraire"
                            // label="Select numeraire"
                            required
                        />
                    </div>
                </SimpleGrid>
            </Card>
            <Card withBorder p="xl" radius="md" mt="lg">
                <Title order={3}>Asset Tokens</Title>
                <Text size="xl" mt="md">{assets?.length.toLocaleString()}</Text>
                <Text size={subTextSize} color="dimmed">Number of assets</Text>
                <Group mt="lg">
                    <Table
                        verticalSpacing="sm"
                        style={{ width: "100%" }}
                        highlightOnHover
                    >
                        <thead>
                            <tr>
                                {/* <th>#</th> */}
                                <th><Text size={headerTextSize}>Name</Text></th>
                                {address ?
                                    <th><Text size={headerTextSize}>Balance ({numeraire.symbol})</Text></th> : null}
                                <th><Text size={headerTextSize}>Price ({numeraire.symbol})</Text></th>
                                {/* <th><Text size={headerTextSize}>Weight</Text></th> */}
                                <th><Text size={headerTextSize}>Reserves ({numeraire.symbol})</Text></th>
                                <th><Text size={headerTextSize}>Fee (bps)</Text></th>
                                <th><Text size={headerTextSize}>Tuning (k)</Text></th>
                            </tr>
                        </thead>
                        <tbody>{rows}</tbody>
                    </Table>
                </Group>
            </Card>
        </Container>
    );
};

export default Dashboard;
