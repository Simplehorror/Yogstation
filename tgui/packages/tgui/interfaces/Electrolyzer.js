import { Fragment } from 'inferno';
import { useBackend } from '../backend';
import { Button, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const Electrolyzer = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={400}
      height={305}>
      <Window.Content>
        <Section
          title="Power"
          buttons={(
            <Fragment>
              <Button
                icon="eject"
                content="Eject Cell"
                disabled={!data.hasPowercell || !data.open}
                onClick={() => act('eject')} />
              <Button
                icon={data.on ? 'power-off' : 'times'}
                content={data.on ? 'On' : 'Off'}
                selected={data.on}
                disabled={!data.hasPowercell || (!data.on && data.powerLevel <= 0)}
                onClick={() => act('power')} />
            </Fragment>
          )}>
          <LabeledList>
            <LabeledList.Item
              label="Cell"
              color={!data.hasPowercell && 'bad'}>
              {data.hasPowercell && (
                <ProgressBar
                  value={data.powerLevel / 100}
                  content={data.powerLevel + '%'}
                  ranges={{
                    good: [0.6, Infinity],
                    average: [0.3, 0.6],
                    bad: [-Infinity, 0.3],
                  }} />
              ) || 'None'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
