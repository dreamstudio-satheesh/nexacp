type FuLocaleMessage = Record<string, unknown>;

const fuLocales: Record<string, FuLocaleMessage> = {
    en: {
        fu: {
            table: {
                more: 'More',
                custom_table_rows: 'Custom columns',
            },
            steps: {
                cancel: 'Cancel',
                prev: 'Previous',
                next: 'Next',
                finish: 'Finish',
            },
        },
    },
};

export const getFuLocaleMessage = (locale: string) => {
    return fuLocales[locale] || fuLocales.en;
};
