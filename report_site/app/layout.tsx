import type {Metadata} from 'next'

export const metadata: Metadata = {
  title: 'PopHIVE Data Report',
  description: 'PopHIVE data report.',
}

export default function RootLayout({children}: Readonly<{children: React.ReactNode}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
