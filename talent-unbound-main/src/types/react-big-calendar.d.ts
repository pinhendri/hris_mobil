declare module "react-big-calendar" {
  import * as React from "react";

  export interface Event {
    title: string;
    start: Date;
    end: Date;
    allDay?: boolean;
    resource?: any;
  }

  export interface CalendarProps {
    localizer: any;
    events: Event[];
    startAccessor?: string | ((event: Event) => Date);
    endAccessor?: string | ((event: Event) => Date);
    style?: React.CSSProperties;
    eventPropGetter?: (
      event: Event,
      start: Date,
      end: Date,
      isSelected: boolean
    ) => { style?: React.CSSProperties; className?: string };
  }

  export class Calendar extends React.Component<CalendarProps> {}

  export function dateFnsLocalizer(config: {
    format: (date: Date, formatStr: string, options?: any) => string;
    parse: (value: string, formatStr: string, baseDate: Date, options?: any) => Date;
    startOfWeek: (date: Date, options?: any) => Date;
    getDay: (date: Date) => number;
    locales: { [key: string]: any };
  }): any;
}
